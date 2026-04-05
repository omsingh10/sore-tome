import { ChatGroq } from "@langchain/groq";
import { CloudflareWorkersAI } from "@langchain/cloudflare";
import { ChatCerebras } from "@langchain/cerebras";
import { Runnable, RunnableConfig } from "@langchain/core/runnables";
import { logger } from "../../shared/Logger";
import IORedis from "ioredis";
import dotenv from "dotenv";

dotenv.config();

export type TaskType = "CHITCHAT" | "RETRIEVAL" | "EXTRACTION";

interface ProviderMetadata {
  name: string;
  costPer1MInput: number;
  costPer1MOutput: number;
}

const PROVIDER_METADATA: Record<string, ProviderMetadata> = {
  "llama-3.1-8b-instant": { name: "Groq", costPer1MInput: 0.05, costPer1MOutput: 0.08 },
  "llama-3.3-70b-versatile": { name: "Groq", costPer1MInput: 0.59, costPer1MOutput: 0.79 },
  "llama-3.1-8b": { name: "Cerebras", costPer1MInput: 0.1, costPer1MOutput: 0.1 },
  "llama-3.3-70b": { name: "Cerebras", costPer1MInput: 0.6, costPer1MOutput: 0.6 },
  "@cf/meta/llama-3.1-8b-instruct": { name: "Cloudflare", costPer1MInput: 0.05, costPer1MOutput: 0.05 },
};

export class ProviderService {
  private static instance: ProviderService;
  private redis: IORedis;
  private readonly CB_PREFIX = "circuit_breaker:provider:";
  private readonly CB_THRESHOLD = 3;
  private readonly CB_COOLDOWN = 60; // seconds

  private constructor() {
    this.redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
  }

  public static getInstance(): ProviderService {
    if (!ProviderService.instance) {
      ProviderService.instance = new ProviderService();
    }
    return ProviderService.instance;
  }

  private async isAvailable(providerId: string): Promise<boolean> {
    const key = `${this.CB_PREFIX}${providerId}`;
    const failures = await this.redis.get(key);
    return !failures || parseInt(failures) < this.CB_THRESHOLD;
  }

  private async reportFailure(providerId: string) {
    const key = `${this.CB_PREFIX}${providerId}`;
    const failures = await this.redis.incr(key);
    if (failures === 1) {
      await this.redis.expire(key, this.CB_COOLDOWN);
    }
  }

  /**
   * Smart Model Routing based on Task Type and Provider Health.
   */
  public async getRouteModel(
    taskType: TaskType, 
    context: { requestId: string; userId: string; societyId: string }
  ): Promise<Runnable> {
    const startTime = Date.now();

    // 1. Define Model Instances (Free Tiers Only)
    const models = {
      groq: taskType === "EXTRACTION" 
        ? new ChatGroq({ apiKey: process.env.GROQ_API_KEY, model: "llama-3.3-70b-versatile", temperature: 0 })
        : new ChatGroq({ apiKey: process.env.GROQ_API_KEY, model: "llama-3.1-8b-instant", temperature: 0.7 }),
      cerebras: taskType === "EXTRACTION"
        ? new ChatCerebras({ apiKey: process.env.CEREBRAS_API_KEY, model: "llama-3.3-70b", temperature: 0 })
        : new ChatCerebras({ apiKey: process.env.CEREBRAS_API_KEY, model: "llama-3.1-8b", temperature: 0.7 }),
      cloudflare: new CloudflareWorkersAI({
        model: "@cf/meta/llama-3.1-8b-instruct",
        cloudflareAccountId: process.env.CLOUDFLARE_ACCOUNT_ID,
        cloudflareApiToken: process.env.CLOUDFLARE_API_TOKEN,
      }),
    };

    // 2. Dynamic Fallback Chain based on Availability
    const chainIds = ["groq", "cerebras", "cloudflare"];
    const activeChain: Runnable[] = [];

    for (const id of chainIds) {
      if (await this.isAvailable(id)) {
        activeChain.push((models as any)[id]);
      }
    }

    if (activeChain.length === 0) {
      logger.warn(context, "All providers down! Falling back to emergency Cloudflare");
      activeChain.push(models.cloudflare);
    }


    const primary = activeChain[0];
    const fallbacks = activeChain.slice(1);

    const resilientModel = primary.withFallbacks({ fallbacks });

    // 3. Wrapped Invoke for Logging & Cost Tracking
    const originalInvoke = resilientModel.invoke.bind(resilientModel);
    
    resilientModel.invoke = async (input, options?: RunnableConfig) => {
      try {
        const result = await originalInvoke(input, options);
        const duration = Date.now() - startTime;
        
        let modelName = "unknown";
        let usage = { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 };

        // Attempt to extract usage and model info from metadata
        if ((result as any).response_metadata) {
          const meta = (result as any).response_metadata;
          modelName = meta.model_name || meta.modelId || "unknown";
          usage = meta.tokenUsage || meta.usage || usage;
        }

        const metadata = PROVIDER_METADATA[modelName] || { name: "Unknown", costPer1MInput: 0, costPer1MOutput: 0 };
        const cost = (usage.prompt_tokens * metadata.costPer1MInput + usage.completion_tokens * metadata.costPer1MOutput) / 1000000;

        logger.info({
          ...context,
          provider: metadata.name,
          model: modelName,
          latency_ms: duration,
          tokens: usage.total_tokens,
          cost_usd: cost.toFixed(6),
          status: "success"
        }, "AI Gateway Request Successful");

        return result;
      } catch (error: any) {
        logger.error({
          ...context,
          error: error.message,
          status: "failed"
        }, "AI Gateway Request Failed");
        throw error;
      }
    };

    return resilientModel;
  }
}
