import { Queue, Worker, Job } from "bullmq";
import { ParserService } from "./ParserService";
import { VectorStoreService } from "./VectorStoreService";
import IORedis from "ioredis";

export class AIQueueService {
  private static instance: AIQueueService;
  private queue: Queue;
  private connection: IORedis;

  private constructor() {
    this.connection = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
    this.queue = new Queue("ai-document-inbox", { connection: this.connection });
    this.initWorker();
  }

  public static getInstance(): AIQueueService {
    if (!AIQueueService.instance) {
      AIQueueService.instance = new AIQueueService();
    }
    return AIQueueService.instance;
  }

  /**
   * Adds a document processing job to the queue.
   */
  public async addIngestionJob(filePath: string, society_id: string) {
    await this.queue.add("process-doc", { filePath, society_id });
  }

  /**
   * Worker processes each job: Parse -> Embed -> Store (pgvector).
   */
  private initWorker() {
    new Worker("ai-document-inbox", async (job: Job) => {
      const { filePath, society_id } = job.data;
      
      const parser = ParserService.getInstance();
      const vectorStore = VectorStoreService.getInstance();

      // 1. Process & Chunk (Docling/ParserService)
      const docs = await parser.processFile(filePath, society_id);

      // 2. Embed & Save to pgvector
      const store = await vectorStore.getVectorStore(society_id);
      await store.addDocuments(docs);
      
      console.log(`✅ AI: Successfully ingested ${docs.length} chunks for society ${society_id}`);
    }, { connection: this.connection });
  }
}
