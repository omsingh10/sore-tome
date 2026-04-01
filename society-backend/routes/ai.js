const express = require("express");
const router = express.Router();
const { authMiddleware } = require("../middleware/auth");
const { chatWithAI } = require("../services/aiService");

// POST /ai/chat — resident sends a message to the AI
// Body: { message, history? }
// history = [{ role: "user"|"assistant", content: "..." }]  (last few turns for context)
router.post("/chat", authMiddleware, async (req, res) => {
  try {
    const { message, history = [] } = req.body;

    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({ error: "message is required" });
    }
    if (message.length > 500) {
      return res.status(400).json({ error: "message too long (max 500 chars)" });
    }

    const reply = await chatWithAI(message.trim(), history);
    res.json({ reply });
  } catch (err) {
    console.error("AI chat error:", err.message);
    res.status(500).json({ error: "AI is temporarily unavailable. Please try again." });
  }
});

module.exports = router;
