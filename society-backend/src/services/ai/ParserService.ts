import * as fs from "fs";
import * as path from "path";
import { Document } from "@langchain/core/documents";
import { RecursiveCharacterTextSplitter } from "@langchain/textsplitters";
import { PDFLoader } from "@langchain/community/document_loaders/fs/pdf";
import { OpenAIEmbeddings } from "@langchain/openai";
import { logger } from "../../shared/Logger";
import dotenv from "dotenv";

dotenv.config();

export class ParserService {
  private static instance: ParserService;
  private embeddings: OpenAIEmbeddings;

  private constructor() {
    this.embeddings = new OpenAIEmbeddings({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "text-embedding-3-small",
    });
  }

  public static getInstance(): ParserService {
    if (!ParserService.instance) {
      ParserService.instance = new ParserService();
    }
    return ParserService.instance;
  }

  /**
   * Processes a local file, parses it, and applies Semantic Chunking.
   */
  public async processFile(filePath: string, society_id: string): Promise<Document[]> {
    const startTime = Date.now();
    const ext = path.extname(filePath).toLowerCase();
    
    // 1. Data Loading
    const loader = new PDFLoader(filePath, { splitPages: false });
    const rawDocs = await loader.load();
    const fullText = rawDocs.map(d => d.pageContent).join("\n\n");

    // 2. Semantic Chunking Implementation
    // We split into sentences first, then group by semantic similarity.
    const chunks = await this.semanticChunking(fullText);

    const result = chunks.map((content, idx) => new Document({
      pageContent: content,
      metadata: {
        society_id,
        source: path.basename(filePath),
        chunk_index: idx,
        processed_at: new Date().toISOString(),
      },
    }));

    logger.info({
      file: path.basename(filePath),
      chunks_count: result.length,
      duration_ms: Date.now() - startTime
    }, "Document Semantic Chunking Completed");

    return result;
  }

  /**
   * Custom Semantic Chunking Logic
   * Groups sentences based on embedding similarity breakpoints.
   */
  private async semanticChunking(text: string, threshold: number = 0.85): Promise<string[]> {
    // Stage 1: Split into sentences (Initial units)
    const sentenceSplitter = new RecursiveCharacterTextSplitter({
      chunkSize: 300,
      chunkOverlap: 0,
      separators: ["\n\n", "\n", ". ", "? ", "! "],
    });
    
    const rawSentences = await sentenceSplitter.splitText(text);
    if (rawSentences.length <= 1) return rawSentences;

    // Stage 2: Embed sentences
    const embeddings = await this.embeddings.embedDocuments(rawSentences);

    // Stage 3: Detect semantic breakpoints
    const chunks: string[] = [];
    let currentChunk = [rawSentences[0]];

    for (let i = 1; i < rawSentences.length; i++) {
      const similarity = this.cosineSimilarity(embeddings[i - 1], embeddings[i]);
      
      // If the topic changes (similarity drops below threshold), start a new chunk
      if (similarity < threshold) {
        chunks.push(currentChunk.join(" ").trim());
        currentChunk = [rawSentences[i]];
      } else {
        currentChunk.push(rawSentences[i]);
      }
    }
    
    chunks.push(currentChunk.join(" ").trim());
    return chunks;
  }

  private cosineSimilarity(vecA: number[], vecB: number[]): number {
    const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
    const magA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
    const magB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
    return dotProduct / (magA * magB);
  }
}
