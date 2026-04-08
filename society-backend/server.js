const Sentry = require("@sentry/node");
const { logger } = require("./src/shared/Logger");

// ─── Init Sentry ─────────────────────────────────────────────────────────────
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const { initFirebase } = require("./config/firebase");

// ─── Init Firebase ─────────────────────────────────────────────────────────────
initFirebase();

const app = express();

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: "*" })); 
app.use((req, res, next) => {
  logger.info({ method: req.method, url: req.url }, "Incoming Request");
  next();
});
app.use(express.json({ limit: "5mb" }));

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use("/auth", require("./routes/auth"));   // register, login, approve/reject
app.use("/users", require("./routes/users"));
app.use("/notices", require("./routes/notices"));
app.use("/issues", require("./routes/issues"));
app.use("/funds", require("./routes/funds"));
app.use("/rules", require("./routes/rules"));
app.use("/events", require("./routes/events"));
app.use("/ai", require("./src/routes/ai").default);
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
// Sentry error handler must be before any other error middleware
Sentry.setupExpressErrorHandler(app);

app.use((err, req, res, next) => {
  logger.error(err, "Unhandled error occured");
  res.status(500).json({ error: "Internal server error" });
});

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🏘️  Society Backend running on port ${PORT}`);
  console.log(`📋 Routes: /users /notices /issues /funds /rules /events /ai`);
  console.log(`🤖 AI chatbot: POST /ai/chat\n`);
});
