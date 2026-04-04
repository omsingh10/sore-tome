import { PGVectorStore } from "@langchain/community/vectorstores/pgvector";
import { OpenAIEmbeddings } from "@langchain/openai";
import { Pool, PoolConfig } from "pg";
import { Document } from "@langchain/core/documents";
import { logger } from "../../shared/Logger";
import dotenv from "dotenv";

dotenv.config();

export class VectorStoreService {
  private static instance: VectorStoreService;
  private pool: Pool;
  private embeddings: OpenAIEmbeddings;

  private constructor() {
    const config: PoolConfig = {
      connectionString: process.env.DATABASE_URL,
    };
    this.pool = new Pool(config);
    this.embeddings = new OpenAIEmbeddings({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "text-embedding-3-small",
    });
  }

  public static getInstance(): VectorStoreService {
    if (!VectorStoreService.instance) {
      VectorStoreService.instance = new VectorStoreService();
    }
    return VectorStoreService.instance;
  }

  /**
   * Returns the underlying PGVectorStore instance.
   */
  public async getVectorStore(): Promise<PGVectorStore> {
    return await PGVectorStore.initialize(this.embeddings, {
      pool: this.pool,
      tableName: "document_chunks",
      columns: {
        idColumnName: "id",
        vectorColumnName: "vector",
        contentColumnName: "content",
        metadataColumnName: "metadata",
      },
    });
  }

  /**
   * Hybrid Search: Combines pgvector (Semantic) and PostgreSQL FTS (Keyword).
   * Uses Reciprocal Rank Fusion (RRF) for result merging.
   * STRICTLY filtered by society_id for multi-tenancy.
   */
  public async hybridSearch(query: string, society_id: string, limit: number = 5) {
    const startTime = Date.now();
    const queryEmbedding = await this.embeddings.embedQuery(query);
    const vectorString = `[${queryEmbedding.join(",")}]`;

    // Reciprocal Rank Fusion (RRF) SQL Query
    // Ensures Keyword matches are prioritized for specific terms (like rule numbers)
    const sql = `
      WITH fulltext_search AS (
          SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(fts_content, plainto_tsquery('english', $1)) DESC) as rank
          FROM document_chunks
          WHERE fts_content @@ plainto_tsquery('english', $1)
          AND (metadata->>'society_id')::text = $3
          LIMIT 20
      ),
      vector_search AS (
          SELECT id, ROW_NUMBER() OVER (ORDER BY vector <=> $2) as rank
          FROM document_chunks
          WHERE (metadata->>'society_id')::text = $3
          LIMIT 20
      )
      SELECT dc.id, dc.content, dc.metadata, SUM(1.0 / (60 + COALESCE(fts.rank, 1000) + COALESCE(vec.rank, 1000))) as rrf_score
      FROM document_chunks dc
      LEFT JOIN fulltext_search fts ON dc.id = fts.id
      LEFT JOIN vector_search vec ON dc.id = vec.id
      WHERE fts.id IS NOT NULL OR vec.id IS NOT NULL
      GROUP BY dc.id, dc.content, dc.metadata
      ORDER BY rrf_score DESC
      LIMIT $4;
    `;

    try {
      const result = await this.pool.query(sql, [query, vectorString, society_id, limit]);
      
      const duration = Date.now() - startTime;
      logger.info({ 
        society_id, 
        duration_ms: duration, 
        results_count: result.rows.length 
      }, "Hybrid Search Completed");

      return result.rows.map(row => new Document({
        pageContent: row.content,
        metadata: row.metadata
      }));
    } catch (error: any) {
      logger.error({ error: error.message, society_id }, "Hybrid Search Failed");
      throw error;
    }
  }

  /**
   * Legacy method maintained for compatibility but now routed to hybrid search.
   */
  public async search(query: string, society_id: string, limit: number = 5) {
    return this.hybridSearch(query, society_id, limit);
  }
}
