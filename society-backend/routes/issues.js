const { authMiddleware, canManageContent } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");
const { logger } = require("../src/shared/Logger");
const { validate } = require("../src/middleware/validate");
const { CreateIssueSchema, UpdateIssueStatusSchema } = require("../src/shared/schemas");

// GET /issues — all issues (admin sees all, residents see their own + open ones)
router.get("/", authMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
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

// GET /issues/:id — single issue (SECURE: Ownership/Admin check)
router.get("/:id", authMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const doc = await db.collection("issues").doc(req.params.id).get();
    
    // Mask existence: if not exists OR not authorized, return 404
    if (!doc.exists) {
      return res.status(404).json({ error: "Issue not found" });
    }

    const data = doc.data();
    const isOwner = data.postedBy === req.user.uid;
    const isAdmin = ["main_admin", "secretary", "admin"].includes(req.user.role);

    if (!isOwner && !isAdmin) {
      logger.warn({ ip, userId: req.user.uid, issueId: req.params.id }, "SEC-WARN: Unauthorized IDOR attempt on issue");
      return res.status(404).json({ error: "Issue not found" }); // Masked 403
    }

    data.createdAt = data.createdAt ? data.createdAt.toDate().toISOString() : null;
    data.updatedAt = data.updatedAt ? data.updatedAt.toDate().toISOString() : null;
    res.json({ id: doc.id, ...data });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching single issue");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /issues — any resident can report an issue
// Body: { title, description, category? }  category = "maintenance" | "security" | "cleanliness" | "other"
router.post("/", authMiddleware, validate(CreateIssueSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { title, description, category, priority } = req.body;
    const db = getDb();
    const docRef = await db.collection("issues").add({
      title,
      description,
      category,
      priority,
      status: "open",
      postedBy: req.user.uid,
      postedByName: req.user.name || req.user.phone || "Unknown",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    logger.info({ ip, userId: req.user.uid, issueId: docRef.id }, "Issue reported successfully");
    res.status(201).json({ id: docRef.id, message: "Issue reported" });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error reporting issue");
    res.status(500).json({ error: "Internal server error" });
  }
});

// PATCH /issues/:id/status — admin only: update issue status
// Body: { status }  status = "open" | "in_progress" | "resolved"
router.patch("/:id/status", authMiddleware, canManageContent, validate(UpdateIssueStatusSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { status, adminNote, priority } = req.body;
    const db = getDb();
    const updates = {
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      resolvedBy: req.user.uid,
    };
    if (status) updates.status = status;
    if (adminNote !== undefined) updates.adminNote = adminNote;
    if (priority) updates.priority = priority;

    await db.collection("issues").doc(req.params.id).update(updates);

    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Issue Updated",
      `Changed issue status to "${status}" for issue ID: ${req.params.id}`
    );

    res.json({ message: "Issue status updated successfully" });
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
