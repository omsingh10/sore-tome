const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
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
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.societyId;
    
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
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateNoticeSchema), async (req, res) => {
  try {
    const { title, body, type } = req.body;
    const societyId = req.societyId;

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

    // AI V2.4: Send push notification to all residents in the society
    const NotificationService = require("../services/notificationService");
    await NotificationService.sendToSociety(societyId, {
      title: `New Notice: ${title}`,
      body: body.length > 100 ? body.substring(0, 97) + "..." : body,
      data: { type: "notice", id: docRef.id }
    });

    res.status(201).json({ id: docRef.id, message: "Notice posted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /notices/:id — admin only
router.delete("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("notices").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Notice not found" });
    }

    await docRef.delete();
    
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
