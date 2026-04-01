const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, mainAdminOnly } = require("../middleware/auth");

// GET /channels - Any logged-in user
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("channels").orderBy("createdAt", "desc").get();
    const channels = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ channels });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels - Admin only
router.post("/", authMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, description, isReadOnly = false, allowedRoles = ["resident", "admin"] } = req.body;
    if (!name) return res.status(400).json({ error: "name is required" });

    const db = getDb();
    const docRef = await db.collection("channels").add({
      name,
      description: description || "",
      isReadOnly,
      allowedRoles,
      createdBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Channel created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /channels/:id - Admin only
router.delete("/:id", authMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const db = getDb();
    await db.collection("channels").doc(req.params.id).delete();
    res.json({ message: "Channel deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /channels/:id/messages - Any logged-in user
router.get("/:id/messages", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const channelRef = db.collection("channels").doc(req.params.id);
    const channelDoc = await channelRef.get();

    if (!channelDoc.exists) return res.status(404).json({ error: "Channel not found" });
    const channelData = channelDoc.data();

    if (req.user.role !== "main_admin" && req.user.role !== "superadmin") {
      if (channelData.allowedRoles && !channelData.allowedRoles.includes(req.user.role)) {
        return res.status(403).json({ error: "You do not have permission to view this channel" });
      }
    }

    const snap = await channelRef.collection("messages")
      .orderBy("createdAt", "desc").limit(50).get();
    
    const messages = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ messages });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/messages - Any logged-in user
router.post("/:id/messages", authMiddleware, async (req, res) => {
  try {
    const { text, senderName, senderFlat } = req.body;
    if (!text) return res.status(400).json({ error: "text is required" });

    const db = getDb();
    const channelRef = db.collection("channels").doc(req.params.id);
    const channelDoc = await channelRef.get();

    if (!channelDoc.exists) return res.status(404).json({ error: "Channel not found" });
    
    const channelData = channelDoc.data();
    if (channelData.isReadOnly && !["main_admin", "secretary"].includes(req.user.role)) {
       return res.status(403).json({ error: "Only admins can post in this channel" });
    }

    if (req.user.role !== "main_admin" && req.user.role !== "superadmin") {
      if (channelData.allowedRoles && !channelData.allowedRoles.includes(req.user.role)) {
        return res.status(403).json({ error: "You do not have permission to post in this channel" });
      }
    }

    const docRef = await channelRef.collection("messages").add({
      text,
      senderId: req.user.uid,
      senderName: senderName || req.user.name || req.user.phone || "Unknown",
      senderFlat: senderFlat || "",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Message sent" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
