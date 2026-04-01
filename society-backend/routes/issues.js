const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageContent } = require("../middleware/auth");

// GET /issues — all issues (admin sees all, residents see their own + open ones)
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { status } = req.query; // optional filter: open | in_progress | resolved

    let issues = [];

    if (req.user.role === "resident") {
      const [mySnap, openSnap] = await Promise.all([
        db.collection("issues").where("postedBy", "==", req.user.uid).get(),
        db.collection("issues").where("status", "==", "open").get()
      ]);
      const map = new Map();
      [...mySnap.docs, ...openSnap.docs].forEach(doc => {
        if (!map.has(doc.id)) {
          const data = doc.data();
          if (!status || data.status === status) {
            map.set(doc.id, {
              id: doc.id,
              ...data,
              createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
              updatedAt: data.updatedAt ? data.updatedAt.toDate().toISOString() : null,
            });
          }
        }
      });
      issues = Array.from(map.values()).sort((a,b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 50);
    } else {
      let query = db.collection("issues").orderBy("createdAt", "desc");
      if (status) query = query.where("status", "==", status);
      const snap = await query.limit(50).get();
      issues = snap.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
          updatedAt: data.updatedAt ? data.updatedAt.toDate().toISOString() : null,
        };
      });
    }

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
    const data = doc.data();
    data.createdAt = data.createdAt ? data.createdAt.toDate().toISOString() : null;
    data.updatedAt = data.updatedAt ? data.updatedAt.toDate().toISOString() : null;
    res.json({ id: doc.id, ...data });
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
      postedByName: req.user.name || req.user.phone || "Unknown",
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
router.patch("/:id/status", authMiddleware, canManageContent, async (req, res) => {
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
    const isAdmin = ["main_admin", "secretary"].includes(req.user.role);
    if (!isOwner && !isAdmin) return res.status(403).json({ error: "Not authorized" });

    await db.collection("issues").doc(req.params.id).delete();
    res.json({ message: "Issue deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
