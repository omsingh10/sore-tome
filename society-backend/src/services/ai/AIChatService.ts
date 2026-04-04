import { ProviderService } from "./ProviderService";
import { VectorStoreService } from "./VectorStoreService";
import { StringOutputParser } from "@langchain/core/output_parsers";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";
import { RunnablePassthrough, RunnableSequence } from "@langchain/core/runnables";
import { Document } from "@langchain/core/documents";

export class AIChatService {
  private static instance: AIChatService;
  private provider: ProviderService;
  private vectorStore: VectorStoreService;

  private constructor() {
    this.provider = ProviderService.getInstance();
    this.vectorStore = VectorStoreService.getInstance();
  }

  public static getInstance(): AIChatService {
    if (!AIChatService.instance) {
      AIChatService.instance = new AIChatService();
    }
    return AIChatService.instance;
  }

  /**
   * Main RAG Chat interaction.
   * Fetches context from pgvector, builds prompt, and invokes LLM (with Groq failover).
   */
  public async chat(message: string, history: any[], society_id: string) {
    // 1. Retrieve relevant context from pgvector (Filtered by society_id)
    const contextResults = await this.vectorStore.search(message, society_id, 4);
    const contextText = contextResults.map((doc: Document) => doc.pageContent).join("\n\n");

    // 2. Setup the Prompt Template
    const prompt = ChatPromptTemplate.fromMessages([
      ["system", "You are the AI Assistant for the society '{society_name}'. Use the following rules and timings to answer the user's question accurately. \n\nContext:\n{context}\n\nStrict Rules:\n- Only answer based on the context.\n- If the info is not in the context, say 'I don't know, please contact the society admin'.\n- Respond in the language used by the user (Hindi/English/Hinglish)."],
      new MessagesPlaceholder("history"),
      ["user", "{input}"],
    ]);

    // 3. Get the Resilient Model (Groq -> OpenAI)
    const model = this.provider.getChatModel();

    // 4. Create the Chain
    const chain = RunnableSequence.from([
      {
        context: () => contextText,
        input: (input: any) => input.message,
        history: (input: any) => input.history,
        society_name: (input: any) => input.society_name,
      },
      prompt,
      model,
      new StringOutputParser(),
    ]);

    // 5. Execute
    const response = await chain.invoke({
      message,
      history,
      society_name: process.env.SOCIETY_NAME || "The Society",
    });

    return {
      reply: response,
      sources: contextResults.map((doc: Document) => doc.metadata.source || "Society Rules"),
    };
  }
}
