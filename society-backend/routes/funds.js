const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageFunds } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");
const { logger } = require("../src/shared/Logger");
const { validate } = require("../src/middleware/validate");
const { CreateTransactionSchema } = require("../src/shared/schemas");

// GET /funds — current month summary
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const snap = await db.collection("funds")
      .where("society_id", "==", req.societyId)
      .orderBy("createdAt", "desc")
      .limit(12)
      .get();

    const funds = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ funds });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching funds");
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /funds/transactions — recent transactions ledger
router.get("/transactions", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const snap = await db
      .collection("transactions")
      .where("society_id", "==", req.societyId)
      .orderBy("createdAt", "desc")
      .limit(30)
      .get();

    const transactions = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ transactions });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching transactions");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /funds/transactions — admin only: add a transaction
router.post("/transactions", authMiddleware, tenantMiddleware, canManageFunds, validate(CreateTransactionSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { title, amount, type, note, category, transactionId } = req.body;
    const db = getDb();
    const docRef = await db.collection("transactions").add({
      society_id: req.societyId, // MANDATORY: Multi-tenancy partition
      title,
      amount: Number(amount),
      type,
      category: category || "Other",
      note: note || "",
      transactionId: transactionId || null,
      addedBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Transaction recorded" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/summary — total collected, spent, balance, and target (Filtered by societyId)
router.get("/summary", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { redis } = require("../src/shared/Redis");
    const [transSnap, settingsSnap] = await Promise.all([
      db.collection("transactions").where("society_id", "==", req.societyId).orderBy("createdAt", "desc").limit(100).get(),
      db.collection("society_settings").doc(req.societyId).get()
    ]);

    let totalCredit = 0;
    let totalDebit = 0;
    const categoryBreakdown = {};

    transSnap.forEach((doc) => {
      const d = doc.data();
      if (d.type === "credit") {
        totalCredit += d.amount;
      } else if (d.type === "debit") {
        totalDebit += d.amount;
        const cat = d.category || "Other";
        categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + d.amount;
      }
    });

    const settings = settingsSnap.exists ? settingsSnap.data() : { target: 200000, currency: "Rs", maintenanceFee: 625 };
    const maintenanceFee = settings.maintenanceFee || 625;

    // AI V3.12: Live Census-based Outstanding Dues Calculation (Filtered by societyId)
    const usersSnap = await db.collection("users")
      .where("society_id", "==", req.societyId)
      .where("status", "==", "approved")
      .get();

    const liableUsers = usersSnap.docs.filter(u => u.data().maintenanceExempt !== true);

    const now = new Date();
    const firstDayTs = getAdmin().firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth(), 1));
    const paidMatch = await db.collection("transactions")
      .where("society_id", "==", req.societyId)
      .where("createdAt", ">=", firstDayTs)
      .where("category", "==", "maintenance")
      .where("type", "==", "credit")
      .get();

    const paidUids = new Set(paidMatch.docs.map(doc => doc.data().addedBy));
    const unpaidCount = liableUsers.filter(u => !paidUids.has(u.data().uid)).length;

    res.json({
      totalCollected: totalCredit,
      totalSpent: totalDebit,
      balance: totalCredit - totalDebit,
      target: settings.target,
      currency: settings.currency,
      percentage: Math.round((totalCredit / (settings.target || 1)) * 100),
      categoryBreakdown,
      outstandingDues: unpaidCount * maintenanceFee,
      overdueCount: unpaidCount,
      topCategories: Object.keys(categoryBreakdown).sort((a, b) => categoryBreakdown[b] - categoryBreakdown[a]).slice(0, 3).join(", ")
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /funds/settings — admin only: set society-wide financial targets
router.post("/settings", authMiddleware, tenantMiddleware, canManageFunds, async (req, res) => {
  try {
    const { target, currency, maintenanceFee } = req.body;
    const db = getDb();
    const settingsRef = db.collection("society_settings").doc(req.societyId);

    const updates = {};
    if (target !== undefined) updates.target = Number(target);
    if (currency) updates.currency = currency;
    if (maintenanceFee !== undefined) updates.maintenanceFee = Number(maintenanceFee);

    await settingsRef.set(updates, { merge: true });

    // Invalidate dashboard cache
    try {
      const { redis } = require("../src/shared/Redis");
      await redis.del(`admin:dashboard:${req.societyId}`);
    } catch (e) {
      console.warn("Redis invalidation skipped:", e.message);
    }

    await AuditLogService.getInstance().log({
      type: 'administrative',
      action: "Settings Updated",
      actorId: req.user.uid,
      actorName: req.user.name || "Admin",
      details: `Updated society financial settings`,
      society_id: req.societyId,
      metadata: updates
    });

    res.json({ message: "Settings updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/maintenance-status (Filtered by societyId)
router.get("/maintenance-status", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const admin = getAdmin();

    const usersSnap = await db.collection("users")
      .where("society_id", "==", req.societyId)
      .where("status", "==", "approved")
      .get();

    const liableUsers = usersSnap.docs
      .map(d => ({ uid: d.id, ...d.data() }))
      .filter(u => u.maintenanceExempt !== true);

    const settingsSnap = await db.collection("society_settings").doc(req.societyId).get();
    const maintenanceFee = settingsSnap.exists ? (settingsSnap.data().maintenanceFee || 625) : 625;

    const now = new Date();
    const monthsToCheck = [];
    for (let i = 0; i < 3; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      monthsToCheck.push({
        name: d.toLocaleString('default', { month: 'short' }),
        start: admin.firestore.Timestamp.fromDate(d),
        end: admin.firestore.Timestamp.fromDate(new Date(d.getFullYear(), d.getMonth() + 1, 0))
      });
    }

    const oldestDate = monthsToCheck[monthsToCheck.length - 1].start;
    const transSnap = await db.collection("transactions")
      .where("society_id", "==", req.societyId)
      .where("createdAt", ">=", oldestDate)
      .where("category", "==", "maintenance")
      .where("type", "==", "credit")
      .get();

    const payments = transSnap.docs.map(doc => doc.data());

    const overdueList = [];
    const paidUids = new Set();

    liableUsers.forEach(user => {
      let monthsMissed = 0;
      monthsToCheck.forEach((month, index) => {
        const hasPaid = payments.some(p =>
          p.addedBy === user.uid &&
          p.createdAt.toMillis() >= month.start.toMillis() &&
          p.createdAt.toMillis() <= month.end.toMillis()
        );

        if (!hasPaid) {
          monthsMissed++;
        } else if (index === 0) {
          paidUids.add(user.uid);
        }
      });

      if (monthsMissed > 0) {
        overdueList.push({
          uid: user.uid,
          name: user.name,
          flatNumber: user.flatNumber,
          amountOwed: monthsMissed * maintenanceFee,
          monthsOverdue: monthsMissed,
          unitInfo: `Unit ${user.flatNumber || 'N/A'} • ${monthsMissed} month${monthsMissed > 1 ? 's' : ''}`
        });
      }
    });

    res.json({
      paid: liableUsers.filter(u => paidUids.has(u.uid)).map(u => ({ uid: u.uid, name: u.name, flatNumber: u.flatNumber })),
      unpaid: overdueList.sort((a, b) => b.amountOwed - a.amountOwed)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Phase 2: Payment Integration (Gateway Agnostic) ────────────────
const { PaymentService } = require("../src/services/payment/PaymentService");

// POST /payments/create-order
router.post("/payments/create-order", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const { amount, currency = "INR", receipt } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const provider = PaymentService.getInstance().getProvider();
    const order = await provider.createOrder(amount, currency, receipt);
    
    res.json(order);
  } catch (err) {
    logger.error({ error: err.message, user: req.user.uid }, "Order Creation Failed");
    res.status(500).json({ error: err.message });
  }
});

// POST /payments/verify
router.post("/payments/verify", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const payload = { ...req.body, ip: req.ip };
    const provider = PaymentService.getInstance().getProvider();
    
    const verification = await provider.verifyPayment(payload);
    
    if (!verification.success) {
      return res.status(400).json({ 
        error: verification.message,
        details: verification.error 
      });
    }

    // On success: Create transaction record
    const { amount, title, category } = req.body;
    const db = getDb();
    
    const docData = {
      society_id: req.societyId,
      title: title || "Maintenance Payment",
      amount: Number(amount),
      type: "credit",
      category: category || "maintenance",
      note: `Gateway: ${provider.name} | ID: ${verification.transactionId}`,
      transactionId: verification.transactionId,
      addedBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("transactions").add(docData);

    // AI V2.4: Log admin action if it's a significant payment
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Payment Verified",
      `Payment of ${amount} verified via ${provider.name}`
    );

    res.json({ 
      success: true, 
      message: "Payment verified and recorded",
      transactionId: verification.transactionId 
    });
  } catch (err) {
    logger.error({ error: err.message }, "Payment Verification Logic Failed");
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
