import IORedis from "ioredis";
import { OpenAIEmbeddings } from "@langchain/openai";
import { logger } from "../../shared/Logger";
import { Pool } from "pg";

export class SemanticCacheService {
  private static instance: SemanticCacheService;
  private redis: IORedis;
  private pool: Pool;
  private embeddings: OpenAIEmbeddings;
  private readonly SIMILARITY_THRESHOLD = 0.95;

  private constructor() {
    this.redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL });
    this.embeddings = new OpenAIEmbeddings({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "text-embedding-3-small",
    });
  }

  public static getInstance(): SemanticCacheService {
    if (!SemanticCacheService.instance) {
      SemanticCacheService.instance = new SemanticCacheService();
    }
    return SemanticCacheService.instance;
  }

  /**
   * Checks for a semantic cache hit in PostgreSQL (using pgvector for 1M+ scale).
   * Note: Using Postgres for Semantic Cache is more scalable than custom Redis logic
   * while still using Redis for exact matches.
   */
  public async get(query: string, societyId: string, context: { requestId: string }): Promise<string | null> {
    const startTime = Date.now();
    
    // 1. Exact Match Check (Redis - Fast Path)
    const exactKey = `cache:exact:${societyId}:${Buffer.from(query).toString("base64")}`;
    const exactHit = await this.redis.get(exactKey);
    if (exactHit) {
      logger.info({ ...context, societyId, type: "exact" }, "Semantic Cache: Exact Hit!");
      return exactHit;
    }

    // 2. Semantic Match Check (PostgreSQL - Scalable Path)
    try {
      const embedding = await this.embeddings.embedQuery(query);
      const vectorString = `[${embedding.join(",")}]`;

      const sql = `
        SELECT response, (embedding <=> $1) as distance
        FROM semantic_cache
        WHERE society_id = $2
        AND (embedding <=> $1) < $3
        ORDER BY distance ASC
        LIMIT 1;
      `;
      
      const result = await this.pool.query(sql, [vectorString, societyId, 1 - this.SIMILARITY_THRESHOLD]);
      
      if (result.rows.length > 0) {
        const hit = result.rows[0].response;
        logger.info({ 
          ...context, 
          societyId, 
          type: "semantic", 
          latency_ms: Date.now() - startTime 
        }, "Semantic Cache: Hit!");
        return hit;
      }
    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "Semantic Cache: Check Failed");
    }

    return null;
  }

  /**
   * Stores a new entry into both Exact and Semantic caches.
   */
  public async set(query: string, response: string, societyId: string, context: { requestId: string }) {
    // 1. Redis Exact Cache
    const exactKey = `cache:exact:${societyId}:${Buffer.from(query).toString("base64")}`;
    await this.redis.set(exactKey, response, "EX", 3600 * 24); // 24h

    // 2. PostgreSQL Semantic Cache
    try {
      const embedding = await this.embeddings.embedQuery(query);
      const vectorString = `[${embedding.join(",")}]`;
      
      const sql = `
        INSERT INTO semantic_cache (society_id, query, response, embedding)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (society_id, query) DO UPDATE SET response = EXCLUDED.response;
      `;
      await this.pool.query(sql, [societyId, query, response, vectorString]);
    } catch (err: any) {
      logger.error({ ...context, error: err.message }, "Semantic Cache: Save Failed");
    }
  }
}
