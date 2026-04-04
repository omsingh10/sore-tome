import { Router, Request, Response } from "express";
import { AIChatService } from "../services/ai/AIChatService";
import { AIQueueService } from "../services/ai/AIQueueService";
import { AIExtractionService } from "../services/ai/AIExtractionService";
import { logger } from "../shared/Logger";
import { z } from "zod";

const router = Router();

/**
 * POST /ai/chat
 * High-performance RAG chat with society context.
 */
router.post("/chat", async (req: Request, res: Response) => {
  try {
    const { message, history } = req.body;
    const society_id = (req as any).user?.society_id || "default_society";

    const chatService = AIChatService.getInstance();
    const result = await chatService.chat(message, history || [], society_id);

    return res.status(200).json(result);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/chat failed");
    return res.status(500).json({ error: "Chat failed", message: error.message });
  }
});

/**
 * POST /ai/extract-form
 * Hardened extraction pipeline with self-correction.
 */
router.post("/extract-form", async (req: Request, res: Response) => {
  try {
    const { documentId, documentText, fields } = req.body;
    const society_id = (req as any).user?.society_id || "default_society";

    // Dynamic Zod Schema generation based on UI request
    const formSchema = z.object({
      formTitle: z.string(),
      fields: z.array(z.object({
        label: z.string(),
        type: z.enum(["text", "number", "date", "dropdown"]),
        options: z.array(z.string()).optional(),
        required: z.boolean(),
      })),
    }).strict();

    const extractionService = AIExtractionService.getInstance();
    const result = await extractionService.extractForm(documentText, formSchema);

    return res.status(200).json(result);
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/extract-form failed");
    return res.status(500).json({ error: "Extraction failed", message: error.message });
  }
});

/**
 * POST /ai/ingest
 */
router.post("/ingest", async (req: Request, res: Response) => {
  try {
    const { filePath } = req.body;
    const society_id = (req as any).user?.society_id || "default_society";

    const queueService = AIQueueService.getInstance();
    await queueService.addIngestionJob(filePath, society_id);

    return res.status(202).json({ message: "Document ingestion started." });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/ingest failed");
    return res.status(500).json({ error: "Ingestion failed", message: error.message });
  }
});

export default router;
