const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageContent } = require("../middleware/auth");

// GET /notices — all residents can see notices (newest first)
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("notices").orderBy("createdAt", "desc").limit(20).get();
    const notices = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ notices });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /notices/:id — single notice
router.get("/:id", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection("notices").doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: "Notice not found" });
    const data = doc.data();
    data.createdAt = data.createdAt ? data.createdAt.toDate().toISOString() : null;
    res.json({ id: doc.id, ...data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /notices — admin only: create a new notice
// Body: { title, body, type? }   type = "general" | "event" | "maintenance" | "festival"
router.post("/", authMiddleware, canManageContent, async (req, res) => {
  try {
    const { title, body, type = "general" } = req.body;
    if (!title || !body) return res.status(400).json({ error: "title and body are required" });

    const db = getDb();
    const docRef = await db.collection("notices").add({
      title,
      body,
      type,
      postedBy: req.user.uid,
      postedByName: req.user.name || req.user.phone || "Unknown",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Notice posted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /notices/:id — admin only
router.delete("/:id", authMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    await db.collection("notices").doc(req.params.id).delete();
    res.json({ message: "Notice deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
