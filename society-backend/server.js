const Sentry = require("@sentry/node");
const { logger } = require("./src/shared/Logger");

// ─── Suppress pg-connection-string SSL deprecation warning ────────────────────
// The 'sslmode=require' alias warning is informational — it does not affect
// connection behaviour. This will become relevant only in pg v9 / pg-conn-str v3.
// Remove this block once those versions are adopted and the URL updated.
process.on('warning', (warning) => {
  if (warning.name === 'Warning' && warning.message && warning.message.includes('sslmode')) {
    return; // suppress pg SSL alias noise
  }
  // Re-emit all other warnings normally
  console.warn(warning.name, warning.message);
});

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
const rateLimit = require("express-rate-limit");

// ─── Rate Limiters ─────────────────────────────────────────────────────────────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: { error: "Too many login attempts, please try again after 15 minutes" },
  standardHeaders: true,
  legacyHeaders: false,
});

const aiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: { error: "AI request limit reached. Please wait a moment." },
  standardHeaders: true,
  legacyHeaders: false,
});

// ─── Init Firebase ─────────────────────────────────────────────────────────────
initFirebase();

const app = express();

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(helmet());

// Production-grade CORS with Whitelist
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(",") 
  : [];

app.use(cors({
  origin: (origin, callback) => {
    // Allow server-to-server or mobile app requests (origin is undefined)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === "development") {
      callback(null, true);
    } else {
      logger.warn({ origin }, "SEC-WARN: Blocked by CORS");
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));
app.use((req, res, next) => {
  logger.info({ method: req.method, url: req.url }, "Incoming Request");
  next();
});
app.use(express.json({ limit: "5mb" }));

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use("/auth", authLimiter, require("./routes/auth"));   // register, login, approve/reject
app.use("/users", require("./routes/users"));
app.use("/notices", require("./routes/notices"));
app.use("/issues", require("./routes/issues"));
app.use("/funds", require("./routes/funds"));
app.use("/rules", require("./routes/rules"));
app.use("/events", require("./routes/events"));
app.use("/ai", aiLimiter, require("./src/routes/ai").default);
app.use("/admin", require("./src/routes/admin_dashboard").default);
app.use("/admin", require("./src/routes/admin_access").default);
app.use("/channels", require("./routes/channels"));
app.use("/admin", require("./routes/admin_flags"));

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
const PORT = process.env.PORT || 3001;
const server = app.listen(PORT, () => {
  console.log(`\n🏘️  Society Backend running on port ${PORT}`);
  console.log(`📋 Routes: /users /notices /issues /funds /rules /events /ai`);
  console.log(`🤖 AI chatbot: POST /ai/chat\n`);
});

// ─── Graceful Shutdown ────────────────────────────────────────────────────────
const { dbManager } = require("./src/shared/Database");
const { redisManager } = require("./src/shared/Redis");

async function shutdown(signal) {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  
  server.close(async () => {
    logger.info("Express server closed");
    
    try {
      await dbManager.close();
      await redisManager.close();
      logger.info("All connections closed. Exiting.");
      process.exit(0);
    } catch (err) {
      logger.error({ error: err.message }, "Error during graceful shutdown");
      process.exit(1);
    }
  });

  // Force exit after 10s if graceful shutdown fails
  setTimeout(() => {
    logger.error("Could not close connections in time, forceful exit");
    process.exit(1);
  }, 10000);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
