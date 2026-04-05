import * as fs from "fs";
import * as path from "path";
import { Document } from "@langchain/core/documents";
import { RecursiveCharacterTextSplitter } from "@langchain/textsplitters";
import { OpenAIEmbeddings } from "@langchain/openai";
import { logger } from "../../shared/Logger";
import { createWorker } from "tesseract.js";
import * as pdfjs from "pdfjs-dist/legacy/build/pdf.mjs";
import { createCanvas } from "canvas";
import dotenv from "dotenv";

dotenv.config();

// Regex for manual heading detection (Chapter, Section, Rule, Part, or all-caps short lines)
const HEADING_REGEX = /^(?:[A-Z]{2,}|(?:Chapter|Section|Rule|Part)\s+\d+|[0-9]{1,2}\.\s+[A-Z][a-z]+)/;

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
   * Processes a document with Heading-Aware Semantic Chunking and OCR Fallback.
   */
  public async processFile(filePath: string, society_id: string, options: { requestId: string }): Promise<Document[]> {
    const startTime = Date.now();
    const fileName = path.basename(filePath);

    try {
      // 1. Direct Text Extraction
      const dataBuffer = fs.readFileSync(filePath);
      const loadingTask = pdfjs.getDocument({ data: new Uint8Array(dataBuffer) });
      const pdf = await loadingTask.promise;
      
      let fullText = "";
      const pages = [];
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const content = await page.getTextContent();
        const text = content.items.map((item: any) => item.str).join(" ");
        fullText += text + "\n\n";
        pages.push({ pageNum: i, text });
      }

      // 2. OCR Fallback Check (If text density is too low, process via OCR)
      const textDensity = fullText.trim().length / pdf.numPages;
      if (textDensity < 100 && process.env.TESSERACT_OCR_ENABLED === "true") {
        logger.info({ ...options, fileName, textDensity }, "Low text density detected. Triggering OCR Fallback...");
        fullText = await this.processOCR(filePath, pdf, options);
      }

      // 3. Heading-Aware Semantic Chunking
      const chunks = await this.semanticChunking(fullText, 0.85);

      const result = chunks.map((content, idx) => new Document({
        pageContent: content,
        metadata: {
          society_id,
          source: fileName,
          chunk_index: idx,
          processed_at: new Date().toISOString(),
        },
      }));

      logger.info({
        ...options,
        fileName,
        chunks_count: result.length,
        latency_ms: Date.now() - startTime,
        status: "success"
      }, "Document Processing & Chunking Completed");

      return result;
    } catch (error: any) {
      logger.error({ ...options, fileName, error: error.message, status: "failed" }, "Document Processing Failed");
      throw error;
    }
  }

  /**
   * Tesseract.js OCR Execution with Page-by-Page chunking as per V3.2 spec.
   */
  private async processOCR(filePath: string, pdf: any, options: { requestId: string }): Promise<string> {
    const worker = await createWorker("eng");
    let ocrFullText = "";

    try {
      // OCR Strategy: 1-2 page chunks (Spec: 10-15 sec per chunk)
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const viewport = page.getViewport({ scale: 2.0 });
        const canvas = createCanvas(viewport.width, viewport.height);
        const context = canvas.getContext("2d");
        
        await page.render({ canvasContext: context as any, viewport }).promise;
        const buffer = canvas.toBuffer("image/png");

        const { data: { text } } = await worker.recognize(buffer);
        ocrFullText += text + "\n\n";
        
        logger.debug({ ...options, pageNum: i }, `OCR Completed for page ${i}`);
      }
      return ocrFullText;
    } finally {
      await worker.terminate();
    }
  }

  /**
   * Heading-Aware Semantic Chunking implementation.
   */
  private async semanticChunking(text: string, threshold: number): Promise<string[]> {
    const rawLines = text.split("\n");
    const sectors: string[] = [];
    let currentSector = "";

    // Grouping by physical headings first
    for (const line of rawLines) {
      if (HEADING_REGEX.test(line.trim()) && currentSector.length > 500) {
        sectors.push(currentSector.trim());
        currentSector = line + "\n";
      } else {
        currentSector += line + "\n";
      }
    }
    sectors.push(currentSector.trim());

    // Applying semantic split on each sector
    const finalChunks: string[] = [];
    for (const sector of sectors) {
      if (sector.length < 1000) {
        finalChunks.push(sector);
        continue;
      }

      const sentenceSplitter = new RecursiveCharacterTextSplitter({
        chunkSize: 500,
        chunkOverlap: 50,
      });
      const sentences = await sentenceSplitter.splitText(sector);
      if (sentences.length <= 1) {
        finalChunks.push(sector);
        continue;
      }

      const embeddings = await this.embeddings.embedDocuments(sentences);
      let currentChunk = [sentences[0]];

      for (let i = 1; i < sentences.length; i++) {
        const similarity = this.cosineSimilarity(embeddings[i - 1], embeddings[i]);
        if (similarity < threshold) {
          finalChunks.push(currentChunk.join(" ").trim());
          currentChunk = [sentences[i]];
        } else {
          currentChunk.push(sentences[i]);
        }
      }
      finalChunks.push(currentChunk.join(" ").trim());
    }

    return finalChunks;
  }

  private cosineSimilarity(vecA: number[], vecB: number[]): number {
    const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
    const magA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
    const magB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
    return dotProduct / (magA * magB);
  }
}
