const { validate } = require("../middleware/validation");
const { CreateNoticeSchema } = require("../src/shared/schemas");

// GET /notices — all residents can see notices (newest first)
// ... (omitting GET routes for brevity)

// POST /notices — admin only: create a new notice
// Body: { title, body, type? }   type = "general" | "event" | "maintenance" | "festival"
router.post("/", authMiddleware, canManageContent, validate(CreateNoticeSchema), async (req, res) => {
  try {
    const { title, body, type } = req.body;


    const db = getDb();
    const docRef = await db.collection("notices").add({
      title,
      body,
      type,
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
