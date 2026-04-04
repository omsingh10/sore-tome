import { ChatGroq } from "@langchain/groq";
import { ChatOpenAI } from "@langchain/openai";
import { CloudflareWorkersAI } from "@langchain/cloudflare";
import { ChatCerebras } from "@langchain/cerebras";
import { Runnable } from "@langchain/core/runnables";
import { logger } from "../../shared/Logger";
import dotenv from "dotenv";

dotenv.config();

export type TaskType = "CHITCHAT" | "RETRIEVAL" | "EXTRACTION";

export class ProviderService {
  private static instance: ProviderService;

  private constructor() {}

  public static getInstance(): ProviderService {
    if (!ProviderService.instance) {
      ProviderService.instance = new ProviderService();
    }
    return ProviderService.instance;
  }

  /**
   * Smart Model Routing based on Task Type.
   * - CHITCHAT / RETRIEVAL: Uses Llama 3.1 8B (Fast/Cheap)
   * - EXTRACTION: Uses Llama 3.3 70B (High Intelligence)
   */
  public getRouteModel(taskType: TaskType): Runnable {
    const startTime = Date.now();

    // 1. Define Models
    
    // GROQ (Primary - Free)
    const groq8b = new ChatGroq({
      apiKey: process.env.GROQ_API_KEY,
      model: "llama-3.1-8b-instant",
      temperature: taskType === "EXTRACTION" ? 0 : 0.7,
    });

    const groq70b = new ChatGroq({
      apiKey: process.env.GROQ_API_KEY,
      model: "llama-3.3-70b-versatile",
      temperature: 0,
    });

    // CEREBRAS (High Speed - Free Tier)
    const cerebras8b = new ChatCerebras({
      apiKey: process.env.CEREBRAS_API_KEY,
      model: "llama-3.1-8b",
      temperature: 0.7,
    });

    const cerebras70b = new ChatCerebras({
      apiKey: process.env.CEREBRAS_API_KEY,
      model: "llama-3.3-70b",
      temperature: 0,
    });

    // CLOUDFLARE (Safety - Free Daily Tier)
    const cloudflareLlama = new CloudflareWorkersAI({
      model: "@cf/meta/llama-3.1-8b-instruct",
      cloudflareAccountId: process.env.CLOUDFLARE_ACCOUNT_ID,
      cloudflareApiToken: process.env.CLOUDFLARE_API_TOKEN,
    });

    // OPENAI (Production - Paid Fallback)
    const openaiMini = new ChatOpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "gpt-4o-mini",
      temperature: taskType === "EXTRACTION" ? 0 : 0.7,
    });

    const openaiStandard = new ChatOpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "gpt-4o",
      temperature: 0,
    });

    // 2. Routing Logic (The Resilience Mesh)
    let primary;
    let fallbacks: Runnable[] = [];

    if (taskType === "EXTRACTION") {
      primary = groq70b;
      // EXTRACTION PATH: Groq 70B -> Cerebras 70B -> OpenAI Standard
      fallbacks = [cerebras70b as any, openaiStandard];
    } else {
      primary = groq8b;
      // CHAT PATH: Groq 8B -> Cerebras 8B -> Cloudflare -> OpenAI Mini
      fallbacks = [cerebras8b as any, cloudflareLlama as any, openaiMini];
    }

    // 3. Resilience Packaging
    const resilientModel = primary.withFallbacks({
      fallbacks: fallbacks,
    });

    // Wrapped invoke to log metrics (Latency, Provider, Status)
    const originalInvoke = resilientModel.invoke.bind(resilientModel);
    resilientModel.invoke = async (input, options) => {
      try {
        const result = await originalInvoke(input, options);
        const duration = Date.now() - startTime;
        
        logger.info({
          taskType,
          duration_ms: duration,
          provider: "resilient-mesh",
          status: "success"
        }, "AI Gateway Request Completed");
        
        return result;
      } catch (error: any) {
        logger.error({
          taskType,
          error: error.message,
          status: "failed"
        }, "AI Gateway Request Failed");
        throw error;
      }
    };

    return resilientModel;
  }
}
