import { Response } from "express";
import { logger } from "../../shared/Logger";
import { ProviderService } from "./ProviderService";
import { AIMemoryService } from "./AIMemoryService";
import { VectorStoreService } from "./VectorStoreService";
import { SemanticCacheService } from "./SemanticCacheService";
import { AIGuardrailsService } from "./AIGuardrailsService";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";
import { HumanMessage, AIMessage, SystemMessage } from "@langchain/core/messages";

export class AIChatService {
  private static instance: AIChatService;
  private provider: ProviderService;
  private memory: AIMemoryService;
  private vectorStore: VectorStoreService;
  private cache: SemanticCacheService;
  private guardrails: AIGuardrailsService;

  private constructor() {
    this.provider = ProviderService.getInstance();
    this.memory = AIMemoryService.getInstance();
    this.vectorStore = VectorStoreService.getInstance();
    this.cache = SemanticCacheService.getInstance();
    this.guardrails = AIGuardrailsService.getInstance();
  }

  public static getInstance(): AIChatService {
    if (!AIChatService.instance) {
      AIChatService.instance = new AIChatService();
    }
    return AIChatService.instance;
  }

  /**
   * Orchestrated Chat with SSE Streaming.
   * Includes Cache, Memory, RAG, it Guardrails.
   */
  public async chat(
    userId: string, 
    societyId: string, 
    userMessage: string, 
    res: Response
  ) {
    const requestId = `chat_${Date.now()}`;
    const context = { requestId, userId, societyId };

    try {
      // 1. Input Guardrails
      const safeInput = await this.guardrails.validateInput(userMessage, context);

      // 2. Semantic Cache Check
      const cached = await this.cache.get(safeInput, societyId, context);
      if (cached) {
        this.streamResponse(res, cached);
        return;
      }

      // 3. RAG Retrieval (Hybrid Search)
      const relatedDocs = await this.vectorStore.hybridSearch(safeInput, societyId, context, 3);
      const ragContext = relatedDocs.map(d => d.pageContent).join("\n---\n");

      // 4. Memory Retrieval (Short-Term)
      const chatHistory = await this.memory.getShortTermHistory(userId, societyId);
      const messages = [
        new SystemMessage(`You are a helpful assistant for a Society Management App. Use the following context to answer if relevant.\nContext:\n${ragContext}`),
        ...chatHistory.map(h => h.role === "human" ? new HumanMessage(h.content) : new AIMessage(h.content)),
        new HumanMessage(safeInput)
      ];

      // 5. SSE Setup
      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      // 6. LLM Invocation with Fallback Timing
      const model = await this.provider.getRouteModel("RETRIEVAL", context);
      const stream = await model.stream(messages);

      let fullResponse = "";
      const timeout = setTimeout(() => {
        logger.warn(context, "AI Streaming Timeout: Sending fallback message");
        res.write(`data: ${JSON.stringify({ content: "\n\nSystem busy, retrying...", status: "fallback" })}\n\n`);
      }, 7000); // 7s timeout as per spec (5-10s)

      for await (const chunk of stream) {
        clearTimeout(timeout);
        const content = chunk.content.toString();
        fullResponse += content;
        res.write(`data: ${JSON.stringify({ content })}\n\n`);
      }

      // 7. Post-Processing: Memory, Cache, Output Guardrails
      const safeOutput = await this.guardrails.validateOutput(fullResponse, context);
      await this.memory.addShortTermMessage(userId, societyId, { role: "human", content: safeInput });
      await this.memory.addShortTermMessage(userId, societyId, { role: "ai", content: safeOutput });
      await this.cache.set(safeInput, safeOutput, societyId, context);

      res.write("data: [DONE]\n\n");
      res.end();

    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "AIChatService.chat Encountered Error");
      res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
      res.end();
    }
  }

  private streamResponse(res: Response, text: string) {
    res.setHeader("Content-Type", "text/event-stream");
    res.write(`data: ${JSON.stringify({ content: text })}\n\n`);
    res.write("data: [DONE]\n\n");
    res.end();
  }
}
