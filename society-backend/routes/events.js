const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly } = require("../middleware/auth");

// GET /events — upcoming events
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("events").orderBy("date", "asc").limit(20).get();
    const events = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ events });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /events — admin only: create an event
// Body: { title, description, date (ISO string), location? }
router.post("/", authMiddleware, adminOnly, async (req, res) => {
  try {
    const { title, description, date, location } = req.body;
    if (!title || !date)
      return res.status(400).json({ error: "title and date are required" });

    const db = getDb();
    const docRef = await db.collection("events").add({
      title,
      description: description || "",
      date: new Date(date),
      location: location || "Society premises",
      createdBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Event created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /events/:id — admin only
router.delete("/:id", authMiddleware, adminOnly, async (req, res) => {
  try {
    const db = getDb();
    await db.collection("events").doc(req.params.id).delete();
    res.json({ message: "Event deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
