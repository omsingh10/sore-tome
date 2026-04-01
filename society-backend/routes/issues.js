const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly } = require("../middleware/auth");

// GET /issues — all issues (admin sees all, residents see their own + open ones)
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { status } = req.query; // optional filter: open | in_progress | resolved

    let query = db.collection("issues").orderBy("createdAt", "desc");
    if (status) query = query.where("status", "==", status);

    const snap = await query.limit(50).get();
    const issues = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ issues });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /issues/:id — single issue
router.get("/:id", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection("issues").doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: "Issue not found" });
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /issues — any resident can report an issue
// Body: { title, description, category? }  category = "maintenance" | "security" | "cleanliness" | "other"
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { title, description, category = "other" } = req.body;
    if (!title || !description)
      return res.status(400).json({ error: "title and description are required" });

    const db = getDb();
    const docRef = await db.collection("issues").add({
      title,
      description,
      category,
      status: "open",
      postedBy: req.user.uid,
      postedByName: req.user.email,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Issue reported" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /issues/:id/status — admin only: update issue status
// Body: { status }  status = "open" | "in_progress" | "resolved"
router.patch("/:id/status", authMiddleware, adminOnly, async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    const validStatuses = ["open", "in_progress", "resolved"];
    if (!validStatuses.includes(status))
      return res.status(400).json({ error: "Invalid status. Use: open | in_progress | resolved" });

    const db = getDb();
    await db.collection("issues").doc(req.params.id).update({
      status,
      adminNote: adminNote || "",
      resolvedBy: req.user.uid,
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.json({ message: `Issue marked as ${status}` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /issues/:id — admin only or issue owner
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection("issues").doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: "Issue not found" });

    const isOwner = doc.data().postedBy === req.user.uid;
    const isAdmin = req.user.role === "admin" || req.user.role === "superadmin";
    if (!isOwner && !isAdmin) return res.status(403).json({ error: "Not authorized" });

    await db.collection("issues").doc(req.params.id).delete();
    res.json({ message: "Issue deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
