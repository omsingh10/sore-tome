import { Queue, Worker, Job, QueueEvents } from "bullmq";
import { ParserService } from "./ParserService";
import { VectorStoreService } from "./VectorStoreService";
import { logger } from "../../shared/Logger";
import IORedis from "ioredis";
import dotenv from "dotenv";

dotenv.config();

export type AITaskType = "DOC_INGESTION" | "BULK_EXTRACTION" | "EMBEDDING_GENERATION" | "OCR_PROCESSING";

export class AIQueueService {
  private static instance: AIQueueService;
  private queue: Queue;
  private connection: IORedis;
  private queueEvents: QueueEvents;

  private constructor() {
    this.connection = new IORedis(process.env.REDIS_URL || "redis://localhost:6379", {
      maxRetriesPerRequest: null,
    });
    this.queue = new Queue("ai-production-queue", {
      connection: this.connection,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: "exponential",
          delay: 5000, // 5s, 10s, 20s
        },
        removeOnComplete: true,
        removeOnFail: false,
      },
    });
    this.queueEvents = new QueueEvents("ai-production-queue", { connection: this.connection });
    this.initWorker();
    this.setupListeners();
  }

  public static getInstance(): AIQueueService {
    if (!AIQueueService.instance) {
      AIQueueService.instance = new AIQueueService();
    }
    return AIQueueService.instance;
  }

  /**
   * Universal method to add AI jobs with priority support.
   */
  public async addJob(taskType: AITaskType, data: any, priority: number = 10) {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    await this.queue.add(taskType, { ...data, requestId }, { priority });
    
    logger.info({
      requestId,
      taskType,
      societyId: data.society_id,
      userId: data.user_id,
    }, "AI Job Queued Successfully");
  }

  private setupListeners() {
    this.queueEvents.on("failed", ({ jobId, failedReason }) => {
      logger.error({ jobId, error: failedReason }, "AI Job Failed permanently (Moved to DLQ)");
    });
  }

  /**
   * Orchestrated Worker: Handles multiple task types with strict multi-tenancy.
   */
  private initWorker() {
    new Worker("ai-production-queue", async (job: Job) => {
      const { taskType, requestId, society_id, userId } = job.data;
      const context = { requestId, societyId: society_id, userId };
      
      const startTime = Date.now();
      logger.info({ ...context, taskType: job.name }, "AI Worker: Processing started");

      try {
        switch (job.name as AITaskType) {
          case "DOC_INGESTION":
            await this.handleIngestion(job.data, context);
            break;
          case "OCR_PROCESSING":
            // Specialized OCR handling if needed (can also be part of ingestion)
            break;
          case "BULK_EXTRACTION":
            // Implement in Phase 5
            break;
          default:
            logger.warn({ ...context, taskType: job.name }, "AI Worker: Unknown task type received");
        }

        logger.info({
          ...context,
          taskType: job.name,
          latency_ms: Date.now() - startTime,
          status: "completed"
        }, "AI Worker: Job completed successfully");

      } catch (error: any) {
        logger.error({
          ...context,
          taskType: job.name,
          error: error.message,
          status: "failed"
        }, "AI Worker: Job processing failed");
        throw error; // Trigger BullMQ retry
      }
    }, { 
      connection: this.connection,
      concurrency: 5 // Specified in OCR Optimization for V3.2
    });
  }

  private async handleIngestion(data: any, context: { requestId: string }) {
    const { filePath, society_id } = data;
    const parser = ParserService.getInstance();
    const vectorStore = VectorStoreService.getInstance();

    // 1. Process & Chunk (includes OCR fallbacks & Heading-aware splitting)
    const docs = await parser.processFile(filePath, society_id, context);

    // 2. Build Vector Store
    const store = await vectorStore.getVectorStore();
    await store.addDocuments(docs);
  }
}
