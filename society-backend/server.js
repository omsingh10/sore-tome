require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const { initFirebase } = require("./config/firebase");

// ─── Init Firebase ─────────────────────────────────────────────────────────────
initFirebase();

const app = express();

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: "*" })); // Restrict to your domain in production
app.use(morgan("dev"));
app.use(express.json({ limit: "10kb" }));

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use("/auth", require("./routes/auth"));   // register, login, approve/reject
app.use("/users", require("./routes/users"));
app.use("/notices", require("./routes/notices"));
app.use("/issues", require("./routes/issues"));
app.use("/funds", require("./routes/funds"));
app.use("/rules", require("./routes/rules"));
app.use("/events", require("./routes/events"));
app.use("/ai", require("./routes/ai"));
app.use("/channels", require("./routes/channels"));

// ─── Health check ─────────────────────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.json({ status: "ok", app: "Society Backend", timestamp: new Date().toISOString() });
});

// ─── 404 handler ──────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Internal server error" });
});

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🏘️  Society Backend running on port ${PORT}`);
  console.log(`📋 Routes: /users /notices /issues /funds /rules /events /ai`);
  console.log(`🤖 AI chatbot: POST /ai/chat\n`);
});
