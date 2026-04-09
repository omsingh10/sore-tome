const express = require("express");
const router = express.Router();
const { getAllFlags, setFlag } = require("../utils/feature_flags");

// ELITE: Feature Toggle System
// GET /admin/flags - Fetch all active toggles
router.get("/flags", (req, res) => {
  res.json(getAllFlags());
});

// POST /admin/flags/:name - Update a toggle (Admin only would go here)
router.post("/flags/:name", (req, res) => {
  const { name } = req.params;
  const { value } = req.body;
  
  if (setFlag(name, value)) {
    res.json({ success: true, name, value });
  } else {
    res.status(404).json({ error: "Flag not found" });
  }
});

module.exports = router;
