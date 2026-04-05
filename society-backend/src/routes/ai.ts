import { Router, Request, Response } from "express";
import { AIChatService } from "../services/ai/AIChatService";
import { AIQueueService } from "../services/ai/AIQueueService";
import { AIExtractionService } from "../services/ai/AIExtractionService";
import { ParserService } from "../services/ai/ParserService";
import { logger } from "../shared/Logger";
import { z } from "zod";

// @ts-ignore
import { authMiddleware } from "../../middleware/auth";

const router = Router();

/**
 * POST /ai/chat
 * High-performance RAG chat with society context.
 * Supports BOTH JSON (for mobile) and SSE (for web).
 */
router.post("/chat", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { message, base64Image, stream = false } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "default_society";

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
    const result = await aiService.chatNonStreaming(userId, societyId, message || "", base64Image);
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

    // Financial Schema for Smart Scan
    const receiptSchema = z.object({
      vendor: z.string().describe("Name of the store or service provider"),
      date: z.string().describe("Date of transaction in YYYY-MM-DD format"),
      amount: z.number().describe("Total amount paid including taxes"),
      tax: z.number().optional().describe("Total tax amount if visible"),
      category: z.string().describe("Expense category (e.g., Maintenance, Utilities, Stationery, Security)"),
    });

    const parser = ParserService.getInstance();
    const extractionService = AIExtractionService.getInstance();

    // 1. OCR Extraction
    const { content } = await parser.parseBase64(base64Image, { requestId, userId, societyId });

    // 2. Structured Data Extraction
    const result = await extractionService.extractForm(
      content, 
      receiptSchema, 
      { requestId, userId, societyId }
    );

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
    const societyId = (req as any).user?.society_id || "default_society";
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
 * POST /ai/ingest
 */
router.post("/ingest", authMiddleware, async (req: Request, res: Response) => {
  try {
    const { filePath } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).user?.society_id || "default_society";

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

export default router;

