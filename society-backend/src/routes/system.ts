import { Router } from "express";
import { outboxService } from "../shared/OutboxService.js";
import { logger } from "../shared/Logger.js";

const router = Router();

/**
 * GET /system/outbox-metrics
 * ❗ SEC FIX: Should be protected by admin role (handled in server middleware)
 */
router.get("/outbox-metrics", async (req, res) => {
  try {
    const metrics = await outboxService.getMetrics();
    
    // Threshold Alerting Logic (V5.2)
    if (metrics.queue.waiting > 1000) {
      logger.fatal({ waiting: metrics.queue.waiting }, "OUTBOX-CRITICAL: Queue backlog detected!");
    }

    res.json(metrics);
  } catch (error: any) {
    logger.error({ error: error.message }, "System Metrics Fetch Failed");
    res.status(500).json({ error: "Failed to fetch metrics" });
  }
});

export default router;
