const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly } = require("../middleware/auth");

// POST /users/register — called after Firebase phone OTP success
// Flutter sends this after first login to save user profile in Firestore
// Body: { name, flatNumber, phone }
router.post("/register", authMiddleware, async (req, res) => {
  try {
    const { name, flatNumber, phone } = req.body;
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
      email: req.user.email || "",
      role: "resident", // default role
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

// GET /users — admin only: list all users
router.get("/", authMiddleware, adminOnly, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("users").orderBy("flatNumber", "asc").get();
    const users = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ users, total: users.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /users/:uid/role — superadmin only: promote to admin
// Body: { role }  role = "resident" | "admin"
router.patch("/:uid/role", authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== "superadmin")
      return res.status(403).json({ error: "Superadmin access required" });

    const { role } = req.body;
    if (!["resident", "admin"].includes(role))
      return res.status(400).json({ error: "role must be resident or admin" });

    const db = getDb();
    const admin = getAdmin();

    // Update Firestore
    await db.collection("users").doc(req.params.uid).update({ role });

    // Update Firebase Auth custom claims (so JWT reflects new role)
    await admin.auth().setCustomUserClaims(req.params.uid, { role });

    res.json({ message: `User role updated to ${role}` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
