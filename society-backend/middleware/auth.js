const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET;

// Verifies the JWT token issued by our own POST /auth/login endpoint
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or invalid Authorization header" });
  }

  const token = authHeader.split("Bearer ")[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = {
      uid: decoded.uid,
      phone: decoded.phone,
      name: decoded.name,
      role: decoded.role, // "resident" | "admin" | "superadmin"
      society_id: decoded.society_id || "main_society",
    };
    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Session expired. Please log in again." });
    }
    return res.status(401).json({ error: "Invalid token. Please log in again." });
  }
}

// Only allow admins and superadmins (legacy helper)
function adminOnly(req, res, next) {
  if (req.user?.role !== "admin" && req.user?.role !== "superadmin" && req.user?.role !== "main_admin") {
    return res.status(403).json({ error: "Admin access required" });
  }
  next();
}

function mainAdminOnly(req, res, next) {
  if (req.user?.role !== "main_admin") {
    return res.status(403).json({ error: "Main admin access required" });
  }
  next();
}

function canManageFunds(req, res, next) {
  const allowed = ["main_admin", "treasurer"];
  if (!allowed.includes(req.user?.role)) {
    return res.status(403).json({ error: "Treasurer or admin access required" });
  }
  next();
}

function canManageContent(req, res, next) {
  const allowed = ["main_admin", "secretary"];
  if (!allowed.includes(req.user?.role)) {
    return res.status(403).json({ error: "Secretary or admin access required" });
  }
  next();
}

module.exports = { authMiddleware, adminOnly, mainAdminOnly, canManageFunds, canManageContent };
