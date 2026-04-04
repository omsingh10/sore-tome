import { ProviderService } from "./ProviderService";
import { StructuredOutputParser } from "@langchain/core/output_parsers";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { z } from "zod";
import { logger } from "../../shared/Logger";

export class AIExtractionService {
  private static instance: AIExtractionService;
  private provider: ProviderService;

  private constructor() {
    this.provider = ProviderService.getInstance();
  }

  public static getInstance(): AIExtractionService {
    if (!AIExtractionService.instance) {
      AIExtractionService.instance = new AIExtractionService();
    }
    return AIExtractionService.instance;
  }

  /**
   * Hardened extraction with Zod strictness and a Refinement Loop.
   */
  public async extractForm(documentText: string, schema: z.ZodObject<any>) {
    const strictSchema = schema.strict(); // ENSURE NO EXTRA FIELDS
    const parser = StructuredOutputParser.fromZodSchema(strictSchema);
    
    const prompt = ChatPromptTemplate.fromTemplate(
      "EXTRACT FORM DATA FROM DOCUMENT.\n{format_instructions}\n\nDOCUMENT:\n{documentText}"
    );

    const model = this.provider.getRouteModel("EXTRACTION");
    const input = await prompt.format({
      documentText,
      format_instructions: parser.getFormatInstructions(),
    });

    try {
      // 1. First Attempt
      const response = await model.invoke(input);
      try {
        return await parser.parse(response.content.toString());
      } catch (parseError: any) {
        // 2. REFINEMENT LOOP: If parsing fails, use a secondary call to fix the JSON
        logger.warn({ error: parseError.message }, "AI: Extraction parsing failed, starting refinement loop...");
        
        const refinerPrompt = ChatPromptTemplate.fromTemplate(
          "FIX THE FOLLOWING INVALID JSON TO MATCH THE SCHEMA.\nSchema: {format_instructions}\nInvalid JSON: {invalid_json}\nError: {error}"
        );
        
        const refinerInput = await refinerPrompt.format({
          format_instructions: parser.getFormatInstructions(),
          invalid_json: response.content.toString(),
          error: parseError.message,
        });

        // Use standard GPT-4o for refinement (Highest intelligence)
        const refinedResponse = await model.invoke(refinerInput);
        return await parser.parse(refinedResponse.content.toString());
      }
    } catch (finalError: any) {
      logger.error({ error: finalError.message }, "AI: Form Extraction hardened pipeline failed.");
      throw finalError;
    }
  }
}
