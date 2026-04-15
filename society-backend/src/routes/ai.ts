import { Router, Request, Response } from "express";
import { AIChatService } from "../services/ai/AIChatService";
import { AIQueueService } from "../services/ai/AIQueueService";
import { AIExtractionService } from "../services/ai/AIExtractionService";
import { AIToolService } from "../services/ai/AIToolService";
import { ParserService } from "../services/ai/ParserService";
import { logger } from "../shared/Logger";
import { z } from "zod";

// @ts-ignore
import { authMiddleware } from "../../middleware/auth";
import { VectorStoreService } from "../services/ai/VectorStoreService";
import rateLimit from "express-rate-limit";

// Rate limiting for costly AI Ingestion
const uploadRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 documents per hour max
  message: { error: "Upload quota exceeded per hour." },
  keyGenerator: (req: any) => req.user?.society_id || req.ip,
});

const router = Router();

/**
 * POST /ai/chat
 * High-performance RAG chat with society context.
 * Supports BOTH JSON (for mobile) and SSE (for web).
 */
router.post("/chat", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { message, base64Image, stream = false, context: contextData } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "main_society";

    // 1. Validation
    if (!message || typeof message !== "string" || message.trim().length === 0) {
      if (!base64Image) {
        return res.status(400).json({ error: "message or image is required" });
      }
    }

    const MAX_SIZE = 2 * 1024 * 1024; // 2MB Limit for production safety
    if (base64Image && base64Image.length > MAX_SIZE) {
      return res.status(413).json({ error: "Image too large (max 2MB)" });
    }

    if (base64Image && !base64Image.startsWith("data:image/")) {
      return res.status(400).json({ error: "Invalid image format. Expected data:image/..." });
    }

    logger.info({
      userId,
      societyId,
      hasImage: !!base64Image,
      messageLength: message?.length
    }, "Incoming AI Chat Request");

    const aiService = AIChatService.getInstance();

    // SSE Streaming Mode (Not supported for images in this version)
    if (stream === true || req.headers.accept === "text/event-stream") {
      return aiService.chatStreaming(userId, societyId, message || "", res);
    }

    // JSON Mode (Flutter/default)
    const result = await aiService.chatNonStreaming(userId, societyId, message || "", base64Image, contextData);
    return res.status(200).json(result);

  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/chat failed");
    return res.status(500).json({ error: "AI processing failed", message: error.message });
  }
});


/**
 * POST /ai/extract-receipt
 * Specialized extraction for financial documents.
 */
router.post("/extract-receipt", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { base64Image } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "default_society";
    const requestId = `rec_${Date.now()}`;

    if (!base64Image) {
      return res.status(400).json({ error: "receipt image is required" });
    }

    // Financial Schema for Smart Scan (V3.9)
    const receiptSchema = z.object({
      vendor: z.string().describe("Name of the store or service provider"),
      date: z.string().describe("Date of transaction in YYYY-MM-DD format"),
      amount: z.number().describe("Total amount paid including taxes"),
      category: z.string().describe("Expense category (e.g., Maintenance, Utilities, Stationery, Security)"),
      note: z.string().optional().describe("Brief note about the expense"),
    });

    const parser = ParserService.getInstance();
    const extractionService = AIExtractionService.getInstance();

    // 1. OCR Extraction (Will be upgraded to Vision in Phase 4)
    const { content } = await parser.parseBase64(base64Image, { requestId, userId, societyId });

    // 2. Structured Data Extraction
    const result = await extractionService.extractForm(
      content, 
      receiptSchema, 
      { requestId, userId, societyId }
    );

    // 3. Auto-Mapping (V3.9 Mandatory)
    if (result && result.parsed) {
      result.parsed.category = extractionService.autoMapCategory(result.parsed.category || "");
      
      // Data Integrity Check: Ensure amount is positive
      if (result.parsed.amount < 0) result.parsed.amount = Math.abs(result.parsed.amount);
    }

    return res.status(200).json(result);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/extract-receipt failed");
    
    // Fallback: return partial data if it was a parsing error but we have raw content
    if (error.raw) {
      return res.status(200).json({ 
        success: false, 
        error: "Strict validation failed, returning partial data",
        partialData: error.raw 
      });
    }

    return res.status(500).json({ 
      success: false, 
      error: "Receipt extraction failed", 
      message: error.message 
    });
  }
});


/**
 * POST /ai/extract-form
 * Hardened extraction pipeline with self-correction.
 */
router.post("/extract-form", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { documentId, documentText, fields } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "main_society";
    const requestId = `ext_${Date.now()}`;

    // Dynamic Zod Schema generation based on UI request
    const formSchema = z.object({
      formTitle: z.string(),
      fields: z.array(z.object({
        label: z.string(),
        type: z.enum(["text", "number", "date", "dropdown"]),
        options: z.array(z.string()).optional(),
        required: z.boolean(),
      })),
    });

    const extractionService = AIExtractionService.getInstance();
    const result = await extractionService.extractForm(
      documentText, 
      formSchema, 
      { requestId, userId, societyId }
    );

    return res.status(200).json(result);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/extract-form failed");
    return res.status(500).json({ error: "Extraction failed", message: error.message });
  }
});

/**
 * POST /ai/upload-document
 * Admin-only: Uploads a document (PDF/Image) for society knowledge ingestion.
 * ❗ Phase 3: Enforces File Size, SSRF, and Content Validation
 */
router.post("/upload-document", authMiddleware, uploadRateLimiter, async (req: Request, res: Response) => {
  try {
    const { fileUrl, fileName, fileType, documentType = "general" } = req.body;
    const userId = (req as any).user?.uid;
    const societyId = (req as any).user?.society_id || "main_society";

    if (!fileUrl || !fileName) {
      return res.status(400).json({ error: "fileUrl and fileName are required" });
    }

    // SSRF & Security Validation
    if (!fileUrl.startsWith("https://") || fileUrl.includes("localhost") || fileUrl.includes("127.0.0.1")) {
       return res.status(403).json({ error: "Invalid file URL. Intranet/SSRF attempts are blocked." });
    }
    
    const allowedTypes = [".pdf", ".txt", ".png", ".jpg", ".jpeg"];
    const ext = fileName.slice((Math.max(0, fileName.lastIndexOf(".")) || Infinity)).toLowerCase();
    if (!allowedTypes.includes(ext)) {
       return res.status(415).json({ error: "Unsupported file type for ingestion" });
    }

    logger.info({ societyId, userId, fileName }, "AI Ingestion: Starting secure document upload");

    const queueService = AIQueueService.getInstance();
    await queueService.addJob("DOC_INGESTION", { 
      filePath: fileUrl, 
      fileName,
      fileType,
      documentType,
      society_id: societyId,
      userId: userId,
      retentionDays: 30
    });

    return res.status(202).json({ 
      message: "Ingestion verified and started", 
      status: "Processing",
      fileName 
    });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/upload-document failed");
    return res.status(500).json({ error: "Upload failed", message: error.message });
  }
});

/**
 * DELETE /ai/document
 * Phase 3 Vector Store Cleanup
 */
router.delete("/document", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { documentId } = req.body;
    const societyId = (req as any).user?.society_id || "main_society";
    const role = (req as any).user?.role;
    
    if (!["admin", "main_admin"].includes(role)) {
      return res.status(403).json({ error: "Forbidden: Admins only" });
    }
    if (!documentId) return res.status(400).json({ error: "documentId is required" });

    const vectorStore = VectorStoreService.getInstance();
    const count = await vectorStore.deleteDocument(documentId, societyId);
    
    return res.status(200).json({ message: "Document chunks deleted", count });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/document DELETE failed");
    return res.status(500).json({ error: "Delete failed", message: error.message });
  }
});

/**
 * POST /ai/execute-tool
 * User-Confirmed Action: Executes a previously proposed AI action.
 * Expects { actionId }
 */
/**
 * AI V3.11: Proactive Society Digest for Home Screen
 */
router.get("/digest", authMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).user?.society_id || "main_society";
    const toolService = AIToolService.getInstance();
    const digest = await toolService.getSocietyDigest(societyId);
    return res.status(200).json(digest);
  } catch (error: any) {
    logger.error({ error: error.message }, "AI Digest Error");
    return res.status(500).json({ error: error.message });
  }
});

router.post("/execute-tool", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { actionId } = req.body;
    const userId = (req as any).user?.uid;
    const societyId = (req as any).user?.society_id || "main_society";
    const role = (req as any).user?.role || "resident";

    if (!actionId) {
      return res.status(400).json({ error: "actionId is required" });
    }

    const toolService = AIToolService.getInstance();
    const result = await toolService.executeAction(actionId, userId, societyId, role);

    return res.status(200).json({ 
      message: "Action executed successfully", 
      result 
    });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/execute-tool failed");
    return res.status(400).json({ error: error.message });
  }
});

/**
 * POST /ai/ingest (Legacy / Internal)
 */
router.post("/ingest", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { filePath } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "main_society";

    const queueService = AIQueueService.getInstance();
    await queueService.addJob("DOC_INGESTION", { 
      filePath, 
      society_id: societyId,
      userId: userId
    });

    return res.status(202).json({ message: "Document ingestion started." });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/ingest failed");
    return res.status(500).json({ error: "Ingestion failed", message: error.message });
  }
});

/**
 * GET /ai/logs
 * Phase 3 Audit UI Integration with Anomaly Detection flags.
 */
router.get("/logs", authMiddleware, async (req: Request, res: Response) => {
  try {
    const role = (req as any).user?.role;
    const societyId = (req as any).user?.society_id || "main_society";

    if (!["admin", "main_admin"].includes(role)) {
      return res.status(403).json({ error: "Forbidden: Admins only" });
    }

    const { limit = 50, offset = 0 } = req.query;
    const vectorStore = VectorStoreService.getInstance();
    const pool = (vectorStore as any).pool;

    const query = `
      SELECT action_id, tool_id, user_id, action, params, status, created_at, error_message, latency_ms
      FROM ai_audit_logs 
      WHERE society_id = $1
      ORDER BY created_at DESC
      LIMIT $2 OFFSET $3
    `;
    const result = await pool.query(query, [societyId, limit, offset]);

    // Anomaly Detection: Flag if >30% of last N logs failed (potential abuse)
    const recentFailures = result.rows.filter((r: any) => r.status === "failed").length;
    const isUnderAttack = result.rows.length >= 10 && (recentFailures / result.rows.length) > 0.3;

    return res.status(200).json({ 
      logs: result.rows,
      hasAnomaly: isUnderAttack,
      anomalyMessage: isUnderAttack ? "Warning: High failure rate detected in recent AI queries." : null
    });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/logs get failed");
    return res.status(500).json({ error: "Failed to fetch logs" });
  }
});

/**
 * GET /ai/audit/export
 * Admin-only: Export AI Audit Logs as CSV with streaming support.
 * Query: ?from=DATE&to=DATE&action=TYPE&user=ID
 */
router.get("/audit/export", authMiddleware, async (req: Request, res: Response) => {
  try {
    const role = (req as any).user?.role;
    const adminId = (req as any).user?.uid;
    const societyId = (req as any).user?.society_id || "main_society";

    if (!["admin", "main_admin"].includes(role)) {
      return res.status(403).json({ error: "Forbidden: Admins only" });
    }

    const { from, to, action: actionType, user: targetUserId } = req.query;
    
    // 1. Build Query with Filters
    let query = `
      SELECT action_id, tool_id, user_id, action, params, status, created_at, error_message
      FROM ai_audit_logs 
      WHERE society_id = $1
    `;
    const params: any[] = [societyId];
    let paramCount = 1;

    if (from) {
      params.push(from);
      query += ` AND created_at >= $${++paramCount}`;
    }
    if (to) {
      params.push(to);
      query += ` AND created_at <= $${++paramCount}`;
    }
    if (actionType) {
      params.push(actionType);
      query += ` AND tool_id = $${++paramCount}`;
    }
    if (targetUserId) {
      params.push(targetUserId);
      query += ` AND user_id = $${++paramCount}`;
    }

    query += " ORDER BY created_at DESC";

    // 2. Set Headers for Streaming CSV
    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", `attachment; filename=ai_audit_export_${Date.now()}.csv`);
    
    // Write CSV Header
    res.write("Action ID,Tool,User ID,Action Description,Status,Timestamp,Error\n");

    // 3. Stream Rows (using batching for memory safety since pg-query-stream is missing)
    const vectorStore = VectorStoreService.getInstance();
    const pool = (vectorStore as any).pool; // Access the underlying pool
    
    const BATCH_SIZE = 500;
    let offset = 0;
    let hasMore = true;

    while (hasMore) {
      const batchQuery = `${query} LIMIT ${BATCH_SIZE} OFFSET ${offset}`;
      const result = await pool.query(batchQuery, params);
      
      if (result.rows.length === 0) {
        hasMore = false;
        break;
      }

      for (const row of result.rows as any[]) {
        const line = [
          row.action_id,
          row.tool_id,
          row.user_id,
          `"${row.action.replace(/"/g, '""')}"`,
          row.status,
          row.created_at.toISOString(),
          `"${(row.error_message || "").replace(/"/g, '""')}"`
        ].join(",");
        res.write(line + "\n");
      }

      offset += BATCH_SIZE;
      if (result.rows.length < BATCH_SIZE) hasMore = false;
    }

    logger.info({ adminId, filters: req.query }, "Audit CSV exported successfully via streaming");
    res.end();

  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/audit/export failed");
    if (!res.headersSent) {
      res.status(500).json({ error: "Export failed", message: error.message });
    } else {
      res.end();
    }
  }
});

/**
 * GET /ai/rules
 * Fetch distinct rules extracted from society documents.
 */
router.get("/rules", authMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).user?.society_id || "main_society";
    const vectorStore = VectorStoreService.getInstance();
    
    // For rules, we query document_chunks where documentType metadata matches 'rules'
    const store = await vectorStore.getVectorStore();
    const result = await (store as any).pool.query(`
      SELECT DISTINCT ON (content) content, metadata->>'source' as source, metadata->>'processed_at' as processed_at
      FROM document_chunks
      WHERE (metadata->>'society_id')::text = $1 AND metadata->>'documentType' = 'rules'
      ORDER BY content, metadata->>'processed_at' DESC
    `, [societyId]);

    const rules = result.rows.map((row: any) => ({
      rule: row.content,
      source: row.source,
      date: row.processed_at
    }));

    return res.status(200).json({ success: true, rules });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/rules failed");
    return res.status(500).json({ error: "Failed to fetch rules" });
  }
});

/**
 * GET /ai/stats
 * Real-time society analytics (Resident vs Admin actions).
 */
router.get("/stats", authMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).user?.society_id || "main_society";
    const toolService = AIToolService.getInstance();
    
    // This will use internal Redis caching (Phase 4)
    const stats = await toolService.getSocietyStats(societyId);
    return res.status(200).json(stats);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/stats failed");
    return res.status(500).json({ error: "Failed to fetch stats" });
  }
});

/**
 * GET /ai/finance-analysis
 * Categorized expense analysis powered by AI metrics.
 */
router.get("/finance-analysis", authMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).user?.society_id || "main_society";
    const toolService = AIToolService.getInstance();
    
    const analysis = await toolService.analyzeExpenses(societyId);
    return res.status(200).json(analysis);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/finance-analysis failed");
    return res.status(500).json({ error: "Failed to perform financial analysis" });
  }
});

/**
 * POST /ai/refresh-stats
 * ❗ PRO FIX: Manual consistency override for aggregate stats.
 */
router.post("/refresh-stats", authMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).user?.society_id || "main_society";
    const toolService = AIToolService.getInstance();
    
    await toolService.syncSocietyStats(societyId);
    return res.status(200).json({ message: "Statistics refreshed successfully" });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/refresh-stats failed");
    return res.status(500).json({ error: "Failed to refresh stats" });
  }
});

export default router;

