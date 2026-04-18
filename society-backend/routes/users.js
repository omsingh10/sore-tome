const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, mainAdminOnly } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");

// POST /users/register — called after Firebase phone OTP success
// Flutter sends this after first login to save user profile in Firestore
// Body: { name, flatNumber, phone, society_id }
router.post("/register", authMiddleware, async (req, res) => {
  try {
    const { name, flatNumber, phone, society_id } = req.body;
    if (!name || !flatNumber)
      return res.status(400).json({ error: "name and flatNumber are required" });

    const db = getDb();
    const userRef = db.collection("users").doc(req.user.uid);
    const existing = await userRef.get();

    if (existing.exists) {
      return res.status(200).json({ message: "User already registered", user: existing.data() });
    }

    const userData = {
      uid: req.user.uid,
      name,
      flatNumber,
      phone: phone || "",
      society_id: society_id || "main_society", // Fallback for legacy if not provided
      role: "resident", // default role
      residentType: "owner", // owner | tenant | guest
      status: "pending",
      maintenanceExempt: false,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    };

    await userRef.set(userData);
    res.status(201).json({ message: "User registered", user: userData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /users/me — get own profile
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection("users").doc(req.user.uid).get();
    if (!doc.exists) return res.status(404).json({ error: "Profile not found. Please register." });
    res.json(doc.data());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /users — admin only: list all users IN THEIR SOCIETY
router.get("/", authMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.user.society_id;
    
    const snap = await db.collection("users")
      .where("society_id", "==", societyId)
      .orderBy("flatNumber", "asc")
      .get();
      
    const users = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ users, total: users.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /users/:uid — main_admin can edit any user's details
router.patch("/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, flatNumber, blockName, role, status, residentType, maintenanceExempt } = req.body;
    const db = getDb();
    const admin = getAdmin();
    const updates = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (name)       updates.name = name;
    if (flatNumber) updates.flatNumber = flatNumber;
    if (blockName !== undefined) updates.blockName = blockName;
    if (role)       updates.role = role;
    if (status)     updates.status = status;
    if (residentType) updates.residentType = residentType;
    if (maintenanceExempt !== undefined) updates.maintenanceExempt = maintenanceExempt;

    await db.collection("users").doc(req.params.uid).update(updates);

    // If role changed, update JWT claims too
    if (role) {
      await admin.auth().setCustomUserClaims(req.params.uid, { role });
    }

    // Log the action for administrative accountability
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Resident Updated",
      `Modified details for User ID: ${req.params.uid}. Fields: ${Object.keys(req.body).join(", ")}`
    );

    res.json({ message: "User updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
