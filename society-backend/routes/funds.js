const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly } = require("../middleware/auth");

// GET /funds — current month summary
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("funds").orderBy("createdAt", "desc").limit(12).get();
    const funds = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
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
    const transactions = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ transactions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /funds/transactions — admin only: add a transaction
// Body: { title, amount, type }  type = "credit" | "debit"
router.post("/transactions", authMiddleware, adminOnly, async (req, res) => {
  try {
    const { title, amount, type, note } = req.body;
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
      note: note || "",
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

module.exports = router;
