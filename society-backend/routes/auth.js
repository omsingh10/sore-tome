const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, adminOnly, mainAdminOnly } = require("../middleware/auth");
const { AuditLogService } = require("../src/services/AuditLogService");

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = "30d";

// ─── REGISTER ─────────────────────────────────────────────────────────────────
// POST /auth/register
// Body: { name, phone, password, flatNumber, blockName? }
// Creates account with status = "pending". Admin must approve before login works.
router.post("/register", async (req, res) => {
    try {
        const { name, phone, password, flatNumber, blockName } = req.body;

        if (!name || !phone || !password || !flatNumber) {
            return res.status(400).json({ error: "name, phone, password and flatNumber are required" });
        }
        if (password.length < 6) {
            return res.status(400).json({ error: "Password must be at least 6 characters" });
        }

        const cleanPhone = phone.replace(/\s+/g, "");
        const db = getDb();

        // Check duplicate phone
        const existing = await db.collection("users").where("phone", "==", cleanPhone).limit(1).get();
        if (!existing.empty) {
            return res.status(409).json({ error: "This phone number is already registered" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const userRef = db.collection("users").doc();
        const userData = {
            uid: userRef.id,
            name,
            phone: cleanPhone,
            password: hashedPassword,
            flatNumber,
            blockName: blockName || "",
            role: "resident",
            status: "pending",       // pending | approved | rejected
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            residentType: "owner",
            maintenanceExempt: false,
            approvedAt: null,
            approvedBy: null,
        };

        await userRef.set(userData);

        // Notification for admins
        await db.collection("notifications").add({
            type: "registration_request",
            title: "New registration request",
            body: `${name} from Flat ${flatNumber}${blockName ? ", Block " + blockName : ""} wants to join.`,
            targetRole: "admin",
            userId: userRef.id,
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        res.status(201).json({
            message: "Registration submitted. Please wait for admin approval before logging in.",
        });
    } catch (err) {
        console.error("Register error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ─── LOGIN ────────────────────────────────────────────────────────────────────
// POST /auth/login
// Body: { phone, password }
router.post("/login", async (req, res) => {
    try {
        const { phone, password } = req.body;
        if (!phone || !password) {
            return res.status(400).json({ error: "phone and password are required" });
        }

        // ── NATIVE LOGIN (Firebase users collection) ──────────────────────────────
        const cleanPhone = phone.replace(/\s+/g, "");
        const db = getDb();

        const snap = await db.collection("users").where("phone", "==", cleanPhone).limit(1).get();
        if (snap.empty) {
            return res.status(401).json({ error: "Invalid phone number or password" });
        }

        const userDoc = snap.docs[0];
        const user = userDoc.data();

        // Check approval status BEFORE checking password
        if (user.status === "pending") {
            return res.status(403).json({
                error: "Your account is pending admin approval. You will be notified once approved.",
                status: "pending",
            });
        }
        if (user.status === "rejected") {
            return res.status(403).json({
                error: "Your registration was not approved. Please contact the society admin.",
                status: "rejected",
            });
        }

        const passwordMatch = await bcrypt.compare(password, user.password);
        if (!passwordMatch) {
            return res.status(401).json({ error: "Invalid phone number or password" });
        }

        const token = jwt.sign(
            { 
                uid: userDoc.id, 
                phone: user.phone, 
                role: user.role, 
                name: user.name,
                society_id: user.society_id || "main_society" 
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        const { password: _, ...safeUser } = user;
        res.json({ token, user: safeUser });
    } catch (err) {
        console.error("Login error:", err);
        res.status(500).json({ error: err.message });
    }
});

// ─── ADMIN: GET PENDING REQUESTS ──────────────────────────────────────────────
// GET /auth/pending
router.get("/pending", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const db = getDb();
        const snap = await db
            .collection("users")
            .where("status", "==", "pending")
            .orderBy("createdAt", "asc")
            .get();

        const users = snap.docs.map((doc) => {
            const { password, ...safe } = doc.data();
            return { id: doc.id, ...safe };
        });

        res.json({ pending: users, count: users.length });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── ADMIN: APPROVE USER ──────────────────────────────────────────────────────
// POST /auth/approve/:uid
router.post("/approve/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const db = getDb();
        const userRef = db.collection("users").doc(req.params.uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) return res.status(404).json({ error: "User not found" });
        if (userDoc.data().status === "approved") {
            return res.status(400).json({ error: "User is already approved" });
        }

        await userRef.update({
            status: "approved",
            approvedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            approvedBy: req.user.uid,
        });

        const userData = userDoc.data();

        await db.collection("notifications").add({
            type: "registration_approved",
            title: "Registration approved!",
            body: `Welcome to the society, ${userData.name}! You can now log in to the app.`,
            targetUserId: req.params.uid,
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        // Log the action
        await AuditLogService.getInstance().logAdminAction(
            req.user,
            "User Approved",
            `Approved ${userData.name} (Flat ${userData.flatNumber})`
        );

        res.json({ message: `${userData.name} has been approved and notified.` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── ADMIN: REJECT USER ───────────────────────────────────────────────────────
// POST /auth/reject/:uid
// Body: { reason? }
router.post("/reject/:uid", authMiddleware, mainAdminOnly, async (req, res) => {
    try {
        const { reason } = req.body;
        const db = getDb();
        const userRef = db.collection("users").doc(req.params.uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) return res.status(404).json({ error: "User not found" });

        await userRef.update({
            status: "rejected",
            rejectedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
            rejectedBy: req.user.uid,
            rejectionReason: reason || "",
        });

        const userData = userDoc.data();

        await db.collection("notifications").add({
            type: "registration_rejected",
            title: "Registration not approved",
            body: reason
                ? `Your registration was not approved. Reason: ${reason}`
                : "Your registration was not approved. Please contact the admin for more information.",
            targetUserId: req.params.uid,
            read: false,
            createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        // Log the action
        await AuditLogService.getInstance().logAdminAction(
            req.user,
            "User Rejected",
            `Rejected ${userData.name} (Flat ${userData.flatNumber}). Reason: ${reason || 'Not specified'}`
        );

        res.json({ message: `${userData.name}'s registration has been rejected.` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── GET MY NOTIFICATIONS ─────────────────────────────────────────────────────
// GET /auth/notifications
router.get("/notifications", authMiddleware, async (req, res) => {
    try {
        const db = getDb();
        let snap;

        if (["admin", "superadmin", "main_admin", "treasurer", "secretary"].includes(req.user.role)) {
            snap = await db
                .collection("notifications")
                .where("targetRole", "==", "admin")
                .orderBy("createdAt", "desc")
                .limit(30)
                .get();
        } else {
            snap = await db
                .collection("notifications")
                .where("targetUserId", "==", req.user.uid)
                .orderBy("createdAt", "desc")
                .limit(30)
                .get();
        }

        const notifications = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.json({ notifications });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── MARK NOTIFICATION AS READ ────────────────────────────────────────────────
// PATCH /auth/notifications/:id/read
router.patch("/notifications/:id/read", authMiddleware, async (req, res) => {
    try {
        const db = getDb();
        await db.collection("notifications").doc(req.params.id).update({ read: true });
        res.json({ message: "Marked as read" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
