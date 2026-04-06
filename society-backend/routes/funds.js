const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageFunds } = require("../middleware/auth");

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

// GET /funds/summary — total collected, spent, balance
router.get("/summary", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("transactions").get();

    let totalCredit = 0;
    let totalDebit = 0;
    snap.forEach((doc) => {
      const d = doc.data();
      if (d.type === "credit") totalCredit += d.amount;
      if (d.type === "debit") totalDebit += d.amount;
    });

    res.json({
      totalCollected: totalCredit,
      totalSpent: totalDebit,
      balance: totalCredit - totalDebit,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/maintenance-status — tracking who paid and who is exempt
router.get("/maintenance-status", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    
    // 1. Get all users
    const usersSnap = await db.collection("users").get();
    const allUsers = usersSnap.docs.map(d => ({id: d.id, ...d.data()}));
    
    // 2. Filter who is expected to pay
    const liableUsers = allUsers.filter(u => u.status === "approved" && u.maintenanceExempt !== true);
    const exemptUsers = allUsers.filter(u => u.maintenanceExempt === true);

    // 3. Get transactions for current month
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const admin = getAdmin();
    const firstDayTs = admin.firestore.Timestamp.fromDate(firstDay);

    const transSnap = await db.collection("transactions")
        .where("createdAt", ">=", firstDayTs)
        .where("type", "==", "credit")
        .get();
        
    const paidUids = new Set();
    transSnap.docs.forEach(doc => {
        const t = doc.data();
        if (t.title && t.title.toLowerCase().includes("maintenance") && t.addedBy) {
            paidUids.add(t.addedBy); // Assumes addedBy tracks the resident's uid that the fee applies to
        }
    });

    const paidList = liableUsers.filter(u => paidUids.has(u.uid));
    const unpaidList = liableUsers.filter(u => !paidUids.has(u.uid));

    res.json({
        paid: paidList.map(u => ({uid: u.uid, name: u.name, flatNumber: u.flatNumber})),
        unpaid: unpaidList.map(u => ({uid: u.uid, name: u.name, flatNumber: u.flatNumber})),
        exempt: exemptUsers.map(u => ({uid: u.uid, name: u.name, flatNumber: u.flatNumber}))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
