/**
 * Middleware to enforce multi-tenancy by extracting societyId from the authenticated user.
 * Assumes the request has already passed through authMiddleware.
 */
function tenantMiddleware(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: "Authentication required for tenant enforcement" });
  }

  const societyId = req.user.society_id;

  if (!societyId) {
    // SECURITY: Reject requests without a valid tenant context
    return res.status(403).json({ error: "Tenant context (societyId) is required for this action" });
  }

  // Inject societyId into the request object for easy access in routes/services
  req.societyId = societyId;
  
  next();
}

module.exports = { tenantMiddleware };
