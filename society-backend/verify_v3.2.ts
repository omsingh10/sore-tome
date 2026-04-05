import { ProviderService } from "./src/services/ai/ProviderService";
import { ParserService } from "./src/services/ai/ParserService";
import { VectorStoreService } from "./src/services/ai/VectorStoreService";
import { AIQueueService } from "./src/services/ai/AIQueueService";
import { AIGuardrailsService } from "./src/services/ai/AIGuardrailsService";
import { SemanticCacheService } from "./src/services/ai/SemanticCacheService";
import { AIMemoryService } from "./src/services/ai/AIMemoryService";
import { AIEvaluationService } from "./src/services/ai/AIEvaluationService";
import { AICostService } from "./src/services/ai/AICostService";
import { AIRateLimitingService } from "./src/services/ai/AIRateLimitingService";
import { AIPromptService } from "./src/services/ai/AIPromptService";
import { AIFeatureFlagService } from "./src/services/ai/AIFeatureFlagService";
import { logger } from "./src/shared/Logger";
import dotenv from "dotenv";

dotenv.config();

async function diagnostic() {
  console.log("\n🚀 --- AI V3.2 DIAGNOSTIC SYSTEM --- 🚀\n");

  const services = [
    { name: "AI Gateway (Provider)", service: ProviderService },
    { name: "RAG Parser", service: ParserService },
    { name: "Vector Store", service: VectorStoreService },
    { name: "Queue System", service: AIQueueService },
    { name: "Guardrails", service: AIGuardrailsService },
    { name: "Semantic Cache", service: SemanticCacheService },
    { name: "Memory", service: AIMemoryService },
    { name: "Evaluation", service: AIEvaluationService },
    { name: "Cost Tracking", service: AICostService },
    { name: "Rate Limiting", service: AIRateLimitingService },
    { name: "Governance (Prompts)", service: AIPromptService },
    { name: "Governance (Flags)", service: AIFeatureFlagService },
  ];

  for (const s of services) {
    try {
      const instance = (s.service as any).getInstance();
      if (instance) {
        console.log(`✅ ${s.name.padEnd(20)}: Initialized`);
      } else {
        throw new Error("Instance is null");
      }
    } catch (err: any) {
      console.log(`❌ ${s.name.padEnd(20)}: FAILED - ${err.message}`);
    }
  }

  console.log("\n--- CORE INFRASTRUCTURE ---");
  try {
    const vectorStore = VectorStoreService.getInstance();
    const store = await vectorStore.getVectorStore();
    console.log("✅ PostgreSQL + pgvector: Connected");
  } catch (err: any) {
    console.log(`❌ PostgreSQL: FAILED - ${err.message}`);
  }

  console.log("\n--- DIAGNOSTIC COMPLETE ---\n");
}

diagnostic();
