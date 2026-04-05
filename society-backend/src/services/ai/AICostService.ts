import { Pool } from "pg";
import IORedis from "ioredis";
import { logger } from "../../shared/Logger";

export class AICostService {
  private static instance: AICostService;
  private pool: Pool;
  private redis: IORedis;

  private constructor() {
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL });
    this.redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
  }

  public static getInstance(): AICostService {
    if (!AICostService.instance) {
      AICostService.instance = new AICostService();
    }
    return AICostService.instance;
  }

  /**
   * Tracks cost at both user, society, and audit levels.
   */
  public async trackCost(data: {
    userId: string;
    societyId: string;
    requestId: string;
    tokens: number;
    cost: number;
  }) {
    // 1. Audit Log (PostgreSQL)
    const sql = `
      INSERT INTO ai_costs (user_id, society_id, request_id, tokens, cost_usd)
      VALUES ($1, $2, $3, $4, $5)
    `;
    
    try {
      await this.pool.query(sql, [data.userId, data.societyId, data.requestId, data.tokens, data.cost]);

      // 2. Rolling Usage (Redis - 30 day window)
      const societyKey = `cost:society:${data.societyId}:month`;
      const userKey = `cost:user:${data.userId}:month`;

      await this.redis.incrbyfloat(societyKey, data.cost);
      await this.redis.incrbyfloat(userKey, data.cost);
      await this.redis.expire(societyKey, 3600 * 24 * 30);
      await this.redis.expire(userKey, 3600 * 24 * 30);

      logger.info({ 
        requestId: data.requestId, 
        cost: data.cost, 
        societyId: data.societyId 
      }, "AI Cost Tracked Successfully");

    } catch (err: any) {
      logger.error({ requestId: data.requestId, error: err.message }, "AI Cost Tracking Failed");
    }
  }

  public async getSocietyMonthlyCost(societyId: string): Promise<number> {
    const key = `cost:society:${societyId}:month`;
    const cost = await this.redis.get(key);
    return cost ? parseFloat(cost) : 0;
  }
}
