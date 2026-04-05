import { Response } from "express";
import { logger } from "../../shared/Logger";
import { ProviderService } from "./ProviderService";
import { AIMemoryService } from "./AIMemoryService";
import { VectorStoreService } from "./VectorStoreService";
import { SemanticCacheService } from "./SemanticCacheService";
import { AIGuardrailsService } from "./AIGuardrailsService";
import { ParserService } from "./ParserService";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";
import { HumanMessage, AIMessage, SystemMessage } from "@langchain/core/messages";

export class AIChatService {
  private static instance: AIChatService;
  private provider: ProviderService;
  private memory: AIMemoryService;
  private vectorStore: VectorStoreService;
  private cache: SemanticCacheService;
  private guardrails: AIGuardrailsService;
  private parser: ParserService;

  private constructor() {
    this.provider = ProviderService.getInstance();
    this.memory = AIMemoryService.getInstance();
    this.vectorStore = VectorStoreService.getInstance();
    this.cache = SemanticCacheService.getInstance();
    this.guardrails = AIGuardrailsService.getInstance();
    this.parser = ParserService.getInstance();
  }


  public static getInstance(): AIChatService {
    if (!AIChatService.instance) {
      AIChatService.instance = new AIChatService();
    }
    return AIChatService.instance;
  }

  /**
   * Safe JSON Parser for AI Responses
   */
  private safeParseAIResponse(text: string): any {
    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      const cleanText = jsonMatch ? jsonMatch[0] : text;
      const parsed = JSON.parse(cleanText);

      if (parsed && parsed.type === "draft" && parsed.title && parsed.content) {
        return parsed;
      }
      if (parsed && parsed.type === "text" && parsed.reply) {
        return parsed;
      }
      return null;
    } catch {
      return null;
    }
  }

  /**
   * JSON-based Non-Streaming Chat for mobile/standard clients.
   */
  public async chatNonStreaming(
    userId: string, 
    societyId: string, 
    userMessage: string,
    base64Image?: string
  ): Promise<any> {
    const requestId = `chat_json_${Date.now()}`;
    const context = { requestId, userId, societyId };

    try {
      let fileContent = "";
      let ocrFailed = false;
      if (base64Image) {
        try {
          // Hardened OCR with 10s timeout protection
          const parsed: any = await Promise.race([
            this.parser.parseBase64(base64Image, { requestId, userId, societyId }),
            new Promise((_, reject) => 
              setTimeout(() => reject(new Error("OCR processing timeout (10s)")), 10000)
            )
          ]);

          const safeContent = parsed.content?.slice(0, 1500) || "";
          fileContent = `[ATTACHED IMAGE CONTENT]:\n${safeContent}\n[IMAGE DESCRIPTION]:\n${parsed.metadata?.description || "N/A"}`;
          
          logger.info({ ...context, imageSize: base64Image.length }, "Image parsed successfully");
        } catch (err) {
          ocrFailed = true;
          logger.warn({ ...context, error: (err as any).message }, "Image processing fallback: continuing without image context");
        }
      }

      const safeInput = await this.guardrails.validateInput(userMessage, context);

      const cached = await this.cache.get(`${safeInput}_${fileContent.length}`, societyId, context);
      if (cached) {
        const parsed = this.safeParseAIResponse(cached);
        return parsed || { type: "text", reply: cached };
      }

      const { messages, sources } = await this.prepareContext(userId, societyId, safeInput, context, fileContent);

      const model = await this.provider.getRouteModel("RETRIEVAL", context);
      const response = await model.invoke(messages);
      const aiText = response.content.toString();

      const parsed = this.safeParseAIResponse(aiText);
      const responseType = parsed ? parsed.type : "text";

      const safeOutput = await this.postProcess(userId, societyId, safeInput, aiText, context);
      
      logger.info({ ...context, responseType }, "AI Chat Response Generated");

      const result = parsed || { type: "text", reply: safeOutput };
      
      // Add sources if available
      if (sources && sources.length > 0) {
        (result as any).sources = sources;
      }

      if (ocrFailed) {
        (result as any).warning = "Image processing failed, showing best possible answer";
      }

      return result;
    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "AIChatService.chatNonStreaming Failed");
      throw error;
    }
  }


  /**
   * SSE-based Streaming Chat for web clients.
   */
  public async chatStreaming(
    userId: string, 
    societyId: string, 
    userMessage: string, 
    res: Response
  ) {
    const requestId = `chat_sse_${Date.now()}`;
    const context = { requestId, userId, societyId };

    try {
      const safeInput = await this.guardrails.validateInput(userMessage, context);

      let fileContent = ""; // No image support in streaming yet
      const { messages, sources } = await this.prepareContext(userId, societyId, safeInput, context, fileContent);

      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      const model = await this.provider.getRouteModel("RETRIEVAL", context);
      const stream = await model.stream(messages);

      let fullResponse = "";
      const timeout = setTimeout(() => {
        logger.warn(context, "AI Streaming Timeout: Sending fallback message");
        res.write(`data: ${JSON.stringify({ content: "\n\nSystem busy, retrying...", status: "fallback" })}\n\n`);
      }, 7000);

      for await (const chunk of stream) {
        clearTimeout(timeout);
        const content = chunk.content.toString();
        fullResponse += content;
        res.write(`data: ${JSON.stringify({ content })}\n\n`);
      }

      await this.postProcess(userId, societyId, safeInput, fullResponse, context);

      res.write("data: [DONE]\n\n");
      res.end();

    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "AIChatService.chatStreaming Failed");
      res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
      res.end();
    }
  }

  /**
   * Shared helper to prepare RAG and Memory context.
   */
  private async prepareContext(
    userId: string, 
    societyId: string, 
    safeInput: string, 
    context: any,
    fileContent: string = ""
  ) {
    const relatedDocs = await this.vectorStore.hybridSearch(safeInput, societyId, context, 3);
    const ragContext = relatedDocs.map(d => d.pageContent).join("\n---\n");

    // Phase 3: Extract sources with snippets
    const sources = relatedDocs.map(d => ({
      file: d.metadata.source || "unknown",
      page: d.metadata.page || 0,
      snippet: d.pageContent.slice(0, 120).trim() + "..."
    }));

    const chatHistory = await this.memory.getShortTermHistory(userId, societyId);
    
    const systemPrompt = `
      You are a helpful assistant for a Society Management App.
      Use the following context to answer if relevant.
      Context: ${ragContext}
      
      ${fileContent ? `[ATTACHED FILE CONTEXT]:\n${fileContent}\n` : ""}

      STRICT FORMATTING RULE:
      1. If the user asks to draft a notice, rule, announcement, or message:
         Return ONLY a JSON object: {"type": "draft", "title": "<short title>", "content": "<detailed content>"}
      2. For all other queries:
         Return plain text response or JSON: {"type": "text", "reply": "<your response>"}
    `;

    const messages = [
      new SystemMessage(systemPrompt),
      ...chatHistory.map(h => h.role === "human" ? new HumanMessage(h.content) : new AIMessage(h.content)),
      new HumanMessage(safeInput)
    ];

    return { messages, ragContext, sources };
  }


  /**
   * Shared helper for post-processing.
   */
  private async postProcess(userId: string, societyId: string, input: string, output: string, context: any) {
    // 1. Output Guardrails
    const safeOutput = await this.guardrails.validateOutput(output, context);

    // 2. Save to Memory
    await this.memory.addShortTermMessage(userId, societyId, { role: "human", content: input });
    await this.memory.addShortTermMessage(userId, societyId, { role: "ai", content: safeOutput });

    // 3. Cache Result (if safe)
    await this.cache.set(input, safeOutput, societyId, context);

    return safeOutput;
  }

  private sendSSEResponse(res: Response, text: string) {
    res.setHeader("Content-Type", "text/event-stream");
    res.write(`data: ${JSON.stringify({ content: text })}\n\n`);
    res.write("data: [DONE]\n\n");
    res.end();
  }
}

