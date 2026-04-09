const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageFunds } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");

// GET /funds — current month summary
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("funds").orderBy("createdAt", "desc").limit(12).get();
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
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/transactions — recent transactions ledger
router.get("/transactions", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db
      .collection("transactions")
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
    res.status(500).json({ error: err.message });
  }
});

// POST /funds/transactions — admin only: add a transaction
// Body: { title, amount, type, category, note, transactionId }
router.post("/transactions", authMiddleware, canManageFunds, async (req, res) => {
  try {
    const { title, amount, type, note, category, transactionId } = req.body;
    if (!title || !amount || !type)
      return res.status(400).json({ error: "title, amount, and type are required" });
    if (!["credit", "debit"].includes(type))
      return res.status(400).json({ error: "type must be credit or debit" });
    if (isNaN(amount) || Number(amount) <= 0)
      return res.status(400).json({ error: "amount must be a positive number" });

    const db = getDb();
    const docRef = await db.collection("transactions").add({
      title,
      amount: Number(amount),
      type,
      category: category || "Other", // V3.9: Add category
      note: note || "",
      transactionId: transactionId || null, // V3.9: Track AI/External IDs
      addedBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Transaction recorded" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/summary — total collected, spent, balance, and target
router.get("/summary", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const [transSnap, settingsSnap] = await Promise.all([
      db.collection("transactions").get(),
      db.collection("society_settings").doc("global").get()
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

    // AI V3.12: Live Census-based Outstanding Dues Calculation
    const usersSnap = await db.collection("users").where("status", "==", "approved").get();
    const liableUsers = usersSnap.docs.filter(u => u.data().maintenanceExempt !== true);
    
    // Check current month payments (V3.12: This identifies exactly who is 'outstanding')
    const now = new Date();
    const firstDayTs = getAdmin().firestore.Timestamp.fromDate(new Date(now.getFullYear(), now.getMonth(), 1));
    const paidMatch = await db.collection("transactions")
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
      percentage: Math.round((totalCredit / settings.target) * 100),
      categoryBreakdown,
      outstandingDues: unpaidCount * maintenanceFee, // Exact missing revenue
      overdueCount: unpaidCount, // residents behind on payments
      topCategories: Object.keys(categoryBreakdown).sort((a, b) => categoryBreakdown[b] - categoryBreakdown[a]).slice(0, 3).join(", ")
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /funds/settings — admin only: set society-wide financial targets
router.post("/settings", authMiddleware, canManageFunds, async (req, res) => {
  try {
    const { target, currency } = req.body;
    const db = getDb();
    const settingsRef = db.collection("society_settings").doc("global");
    const updates = {};
    if (target !== undefined) updates.target = Number(target);
    if (currency) updates.currency = currency;

    await settingsRef.set(updates, { merge: true });

    // Invalidate dashboard cache so changes reflect immediately
    try {
      const IORedis = require("ioredis");
      const redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
      const societyId = req.user.society_id || "global"; // Simplified for now
      await redis.del(`admin:dashboard:${societyId}`);
      await redis.del(`admin:dashboard:default_society`); // Catch-all for current dev state
    } catch (e) {
      console.warn("Redis invalidation skipped:", e.message);
    }

    // Log the action for administrative accountability
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Settings Updated",
      `Updated society settings: ${Object.keys(req.body).join(", ")}`
    );

    res.json({ message: "Settings updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/maintenance-status — tracking who paid and cumulative debt
router.get("/maintenance-status", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const admin = getAdmin();
    
    // 1. Get liable users
    const usersSnap = await db.collection("users").where("status", "==", "approved").get();
    const liableUsers = usersSnap.docs
        .map(d => ({uid: d.id, ...d.data()}))
        .filter(u => u.maintenanceExempt !== true);

    // 2. Fetch society settings for fee
    const settingsSnap = await db.collection("society_settings").doc("global").get();
    const maintenanceFee = settingsSnap.exists ? (settingsSnap.data().maintenanceFee || 625) : 625;

    // 3. Define the last 3 months to check
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

    // 4. Get all maintenance credits for these months
    const oldestDate = monthsToCheck[monthsToCheck.length - 1].start;
    const transSnap = await db.collection("transactions")
        .where("createdAt", ">=", oldestDate)
        .where("category", "==", "maintenance")
        .where("type", "==", "credit")
        .get();

    const payments = transSnap.docs.map(doc => doc.data());

    // 5. Calculate status and debt for each resident
    const overdueList = [];
    const paidUids = new Set(); // current month only for the 'paid' list

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
        paid: liableUsers.filter(u => paidUids.has(u.uid)).map(u => ({uid: u.uid, name: u.name, flatNumber: u.flatNumber})),
        unpaid: overdueList.sort((a, b) => b.amountOwed - a.amountOwed)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
