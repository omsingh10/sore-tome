const express = require("express");
const router = express.Router();
const multer = require("multer");
const { getDb, getAdmin, getStorage } = require("../config/firebase");
const { authMiddleware, mainAdminOnly, canManageContent } = require("../middleware/auth");
const { startMediaCleaner } = require("../utils/mediaCleaner");
const { getAdminBriefing, convertMessageToIssue } = require("../services/channelService");
const crypto = require("crypto");
const { validate } = require("../src/middleware/validate");
const { MediaUploadSchema } = require("../src/shared/schemas");

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

const rateLimit = require("express-rate-limit");

// Anti-Spam: Max 5 messages per second
const messageRateLimiter = rateLimit({
  windowMs: 1000,
  max: 5,
  message: { error: "Slow down. Message rate limit exceeded." },
  standardHeaders: true,
  legacyHeaders: false,
});

// Start the production reliability media cleaner
startMediaCleaner();

// Middleware to check if user has access to a specific channel
async function checkChannelAccess(req, res, next) {
  try {
    const db = getDb();
    const channelId = req.params.id;
    const channelDoc = await db.collection("channels").doc(channelId).get();

    if (!channelDoc.exists) {
      return res.status(404).json({ error: "Channel not found" });
    }

    const data = channelDoc.data();
    // Role-Based Visibility (Smart Enrollment filtering)
    if (req.user.role !== "main_admin" && req.user.role !== "superadmin" && req.user.role !== "secretary") {
      if (!data.allowedRoles || !data.allowedRoles.includes(req.user.role)) {
        return res.status(403).json({ error: "Access denied to this channel" });
      }
    }
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// GET /channels - Any logged-in user
router.get("/", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    let query = db.collection("channels").orderBy("createdAt", "desc");
    
    // Role-Based Visibility (Smart Enrollment filtering)
    if (req.user.role !== "main_admin" && req.user.role !== "superadmin" && req.user.role !== "secretary") {
      query = query.where("allowedRoles", "array-contains", req.user.role);
    }

    const snap = await query.get();
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

// Efficiency: One source of truth for "Mark Read"
router.post("/:id/read", authMiddleware, checkChannelAccess, async (req, res) => {
  try {
    const db = getDb();
    
    const recentMsgs = await db.collection("channels")
      .doc(req.params.id)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(50) 
      .get();

    const batch = db.batch();
    let count = 0;

    recentMsgs.forEach(doc => {
      const data = doc.data();
      const readBy = data.readBy || [];
      if (!readBy.includes(req.user.uid) && data.senderId !== req.user.uid) {
        batch.update(doc.ref, {
          readBy: getAdmin().firestore.FieldValue.arrayUnion(req.user.uid)
        });
        count++;
      }
    });

    if (count > 0) await batch.commit();

    res.json({ success: true, markedRead: count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /channels/:id - Admin/Secretary only (Settings Update)
router.patch("/:id", authMiddleware, canManageContent, async (req, res) => {
  try {
    const { name, description, isReadOnly, allowedRoles, quietHours, smartType, vaultEnabled } = req.body;
    const db = getDb();
    
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (isReadOnly !== undefined) updateData.isReadOnly = isReadOnly;
    if (allowedRoles !== undefined) updateData.allowedRoles = allowedRoles;
    if (quietHours !== undefined) updateData.quietHours = quietHours;
    if (smartType !== undefined) updateData.smartType = smartType;
    if (vaultEnabled !== undefined) updateData.vaultEnabled = vaultEnabled;
    if (moderatorIds !== undefined) updateData.moderatorIds = moderatorIds;

    updateData.updatedAt = getAdmin().firestore.FieldValue.serverTimestamp();

    await db.collection("channels").doc(req.params.id).update(updateData);
    res.json({ message: "Channel settings updated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/messages/:msgId/stamp - Admin only ("Official Stamp")
router.post("/:id/messages/:msgId/stamp", authMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const msgRef = db.collection("channels").doc(req.params.id).collection("messages").doc(req.params.msgId);
    
    await msgRef.update({
      isOfficial: true,
      stampedBy: req.user.uid,
      stampedAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: "Message stamped as official notice" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Consolidated: Send message with rate limiting, security, and media support
router.post("/:id/messages", authMiddleware, checkChannelAccess, messageRateLimiter, async (req, res) => {
  try {
    const { text, clientId, senderName, senderFlat, mediaUrl, mediaType, fileName, smartType = "chat", metadata = {} } = req.body;
    
    const db = getDb();
    const channelRef = db.collection("channels").doc(req.params.id);
    const channelDoc = await channelRef.get();

    if (!channelDoc.exists) return res.status(404).json({ error: "Channel not found" });
    const channelData = channelDoc.data();

    // Security: Enforce READ-ONLY status for non-admins/mods
    const isModerator = channelData.moderatorIds && channelData.moderatorIds.includes(req.user.uid);
    if (channelData.isReadOnly && !["main_admin", "secretary"].includes(req.user.role) && !isModerator) {
       return res.status(403).json({ error: "Only admins and moderators can post in this channel" });
    }

    if (!text && !mediaUrl) {
      return res.status(400).json({ error: "Content is required" });
    }

    // Auto-Delete Announcement: If a new user message is sent, clear the "History Cleared" system msg
    try {
      const annSnap = await channelRef.collection("messages")
        .where("smartType", "==", "clear_announcement")
        .get();
      if (!annSnap.empty) {
        const batch = db.batch();
        annSnap.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
      }
    } catch (e) {
      console.error("Failed to cleanup clear announcement:", e);
    }

    const msgRef = await channelRef.collection("messages").add({
      text: text || "",
      clientId: clientId || null, 
      senderId: req.user.uid,
      senderName: senderName || req.user.name || "Resident",
      senderFlat: senderFlat || "",
      mediaUrl: mediaUrl || null,
      mediaType: mediaType || null,
      fileName: fileName || null,
      smartType,
      metadata,
      deliveredBy: [], 
      deliveredCount: 0,
      readBy: [],
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    
    // Auto-conversion: If message is flagged as an issue creation intent
    if (smartType === 'issue_creation') {
      try {
        const { convertMessageToIssue } = require("../services/channelService");
        await convertMessageToIssue(req.params.id, msgRef.id, req.user);
      } catch (issueErr) {
        console.error("Auto-issue conversion failed:", issueErr);
        // We don't fail the message sending if issue creation fails
      }
    }

    res.status(201).json({ id: msgRef.id, clientId, message: "Message sent" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/messages/:msgId/delivered - Track device receipt
router.post("/:id/messages/:msgId/delivered", authMiddleware, checkChannelAccess, async (req, res) => {
  try {
    const db = getDb();
    const msgRef = db.collection("channels").doc(req.params.id).collection("messages").doc(req.params.msgId);
    
    await db.runTransaction(async (transaction) => {
      const msgSnap = await transaction.get(msgRef);
      if (!msgSnap.exists) return;

      const data = msgSnap.data();
      const deliveredBy = data.deliveredBy || [];

      if (!deliveredBy.includes(req.user.uid)) {
        transaction.update(msgRef, {
          deliveredBy: getAdmin().firestore.FieldValue.arrayUnion(req.user.uid),
          deliveredCount: (data.deliveredCount || 0) + 1
        });
      }
    });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/messages/:msgId/convert-to-issue - Admin only ("Chat-to-Action")
router.post("/:id/messages/:msgId/convert-to-issue", authMiddleware, canManageContent, async (req, res) => {
  try {
    const issueId = await convertMessageToIssue(req.params.id, req.params.msgId, req.user);
    res.json({ issueId, message: "Converted to official issue" });
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

// GET /channels/admin/briefing - AI-Powered Society Pulse Recap
router.get("/admin/briefing", authMiddleware, canManageContent, async (req, res) => {
  try {
    const data = await getAdminBriefing();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/group-buy - Launch a Collective Buying Hub action
router.post("/:id/group-buy", authMiddleware, canManageContent, async (req, res) => {
  try {
    const { dealTitle, targetCount, discount } = req.body;
    const db = getDb();
    
    await db.collection("channels").doc(req.params.id).collection("messages").add({
      text: `🛍️ GROUP DEAL: ${dealTitle}. Get ${discount}% off if ${targetCount} residents join!`,
      senderId: "system",
      senderName: "System Agent",
      smartType: "group_buy",
      metadata: { dealTitle, targetCount, discount, joinedCount: 0, joinedUids: [] },
      isSystemMessage: true,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: "Group deal launched!" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/typing - Real-time Presence & Heartbeat
router.post("/:id/typing", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const presenceRef = db.collection("channels").doc(req.params.id).collection("presence").doc(req.user.uid);
    
    await presenceRef.set({
      name: req.user.name || "Resident",
      role: req.user.role || "resident",
      isTyping: req.body.isTyping || false,
      isOnline: true, 
      timestamp: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// DELETE /channels/:id/messages/:msgId - Soft Delete (Delete for Everyone)
router.delete("/:id/messages/:msgId", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const msgRef = db.collection("channels").doc(req.params.id).collection("messages").doc(req.params.msgId);
    const msgSnap = await msgRef.get();

    if (!msgSnap.exists) return res.status(404).json({ error: "Message not found" });
    const msgData = msgSnap.data();

    // Security: Only sender or main_admin can delete
    if (msgData.senderId !== req.user.uid && req.user.role !== "main_admin") {
      return res.status(403).json({ error: "Permission denied" });
    }

    await msgRef.update({
      text: "🚫 This message was deleted",
      isDeleted: true,
      deletedAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: "Message deleted for everyone" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/clear - Admin only (Wipe Messages)
router.post("/:id/clear", authMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const messagesRef = db.collection("channels").doc(req.params.id).collection("messages");
    
    const snap = await messagesRef.limit(500).get(); 
    if (snap.size === 0) return res.json({ message: "Hub already empty" });

    const batch = db.batch();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    // Announcement of history wipe
    await db.collection("channels").doc(req.params.id).collection("messages").add({
      text: "🧹 Hub history has been cleared by administration.",
      senderId: "system",
      senderName: "System Agent",
      isSystemMessage: true,
      smartType: "clear_announcement",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: "History cleared successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/media — Upload Image/File (HARDENED: UUID Rename + Validation)
router.post("/:id/media", authMiddleware, upload.single("file"), validate(MediaUploadSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const file = req.file; // Already validated by zod middleware
    const { messageId } = req.body; 

    const db = getDb();
    const storage = getStorage();
    const bucket = storage.bucket();
    
    // Security: UUID Renaming to prevent injection/discovery
    const fileExt = file.originalname.split(".").pop() || "bin";
    const secureFileName = `${crypto.randomUUID()}.${fileExt}`;
    const filePath = `channels/${req.params.id}/media/${secureFileName}`;
    const storageFile = bucket.file(filePath);

    await storageFile.save(file.buffer, {
      metadata: { 
        contentType: file.mimetype,
        metadata: {
          originalName: file.originalname,
          uploadedBy: req.user.uid,
          ip
        }
      }
    });

    await storageFile.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

    if (messageId) {
      await db.collection("channels").doc(req.params.id)
        .collection("messages").doc(messageId).update({
          mediaUrl: publicUrl,
          mediaType: file.mimetype.startsWith("image/") ? "image" : "file",
          fileName: file.originalname, // We show the original but store as UUID
          status: "sent",
          updatedAt: getAdmin().firestore.FieldValue.serverTimestamp()
        });
    }

    logger.info({ ip, userId: req.user.uid, fileName: secureFileName }, "Secure file upload completed");

    res.json({ 
      url: publicUrl, 
      fileName: file.originalname, 
      mediaType: file.mimetype.startsWith("image/") ? "image" : "file" 
    });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Secure upload failed");
    res.status(500).json({ error: "File upload failed" });
  }
});

module.exports = router;
