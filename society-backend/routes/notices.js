const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");
const { validate } = require("../src/middleware/validate");
const { CreateNoticeSchema } = require("../src/shared/schemas");

// Middleware specifically for notice management
const canManageContent = (req, res, next) => {
  const role = req.user?.role;
  if (["admin", "main_admin", "secretary"].includes(role)) {
    return next();
  }
  return res.status(403).json({ error: "Forbidden: You don't have permission to manage notices" });
};

// GET /notices — all residents can see notices (newest first)
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.user.society_id;
    
    const snap = await db.collection("notices")
      .where("society_id", "==", societyId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const notices = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ notices });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /notices — admin only: create a new notice
router.post("/", authMiddleware, canManageContent, validate(CreateNoticeSchema), async (req, res) => {
  try {
    const { title, body, type } = req.body;
    const societyId = req.user.society_id;

    const db = getDb();
    const docRef = await db.collection("notices").add({
      title,
      body,
      type,
      society_id: societyId, // Partition ID
      postedBy: req.user.uid,
      postedByName: req.user.name || req.user.phone || "Unknown",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Notice Posted",
      `Posted notice: "${title}"`
    );

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
    
    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Notice Deleted",
      `Deleted notice ID: ${req.params.id}`
    );

    res.json({ message: "Notice deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
