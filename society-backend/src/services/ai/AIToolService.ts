import { z } from "zod";
// @ts-ignore
import { getDb, getAdmin } from "../../../config/firebase";
import { VectorStoreService } from "./VectorStoreService";
import { logger } from "../../shared/Logger";
import { Pool } from "pg";
import crypto from "crypto";
import IORedis from "ioredis";

// Tool Definitions & Schemas
const NoticeSchema = z.object({
  title: z.string().min(5),
  body: z.string().min(10),
  type: z.enum(["general", "event", "maintenance", "festival"]).default("general"),
});

const ExpenseSchema = z.object({
  vendor: z.string(),
  amount: z.number().positive(),
  category: z.string(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  note: z.string().optional(),
});

const ComplaintSchema = z.object({
  title: z.string().min(5),
  description: z.string().min(10),
  location: z.string().optional(),
  priority: z.enum(["low", "medium", "high"]).default("medium"),
});

export type ToolAction = "create_notice" | "log_expense" | "create_complaint";

export class AIToolService {
  private static instance: AIToolService;
  private pool: Pool;
  private redis: IORedis;

  private constructor() {
    // Re-use pool from VectorStoreService for auditing
    const connStr = process.env.DATABASE_URL;
    this.pool = new Pool({ connectionString: connStr });
    this.redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
  }

  public static getInstance(): AIToolService {
    if (!AIToolService.instance) {
      AIToolService.instance = new AIToolService();
    }
    return AIToolService.instance;
  }

  /**
   * PROPOSE: AI suggests an action. We log it as 'Proposed' and return an actionId.
   */
  public async proposeAction(userId: string, societyId: string, tool: ToolAction, params: any) {
    const actionId = crypto.randomUUID();
    
    const sql = `
      INSERT INTO ai_audit_logs (action_id, tool_id, user_id, society_id, action, params, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'Proposed')
      RETURNING action_id;
    `;
    
    await this.pool.query(sql, [actionId, tool, userId, societyId, tool, JSON.stringify(params)]);
    
    logger.info({ actionId, tool, userId }, "AI Action Proposed");
    return { actionId, tool, params, expires_at: new Date(Date.now() + 10 * 60000) };
  }

  /**
   * EXECUTE: User has confirmed. We validate, execute, and update audit.
   */
  public async executeAction(actionId: string, userId: string, societyId: string, role: string) {
    // 1. Fetch from Audit
    const fetchSql = `SELECT * FROM ai_audit_logs WHERE action_id = $1 AND society_id = $2 AND status = 'Proposed'`;
    const res = await this.pool.query(fetchSql, [actionId, societyId]);
    
    if (res.rows.length === 0) {
      throw new Error("Action not found, already executed, or expired.");
    }

    const task = res.rows[0];
    
    // 2. RBAC Check
    this.checkPermissions(task.tool_id, role);

    // 3. Update status to Processing
    await this.updateStatus(actionId, "Processing");

    try {
      let result;
      // 4. Dispatch Tool
      switch (task.tool_id) {
        case "create_notice":
          const noticeData = NoticeSchema.parse(task.params);
          result = await this.createNotice(noticeData, userId);
          break;
        case "log_expense":
          const expenseData = ExpenseSchema.parse(task.params);
          result = await this.logExpense(expenseData, userId, societyId);
          break;
        case "create_complaint":
          const complaintData = ComplaintSchema.parse(task.params);
          const isDuplicate = await this.recentSimilarIssueExists(societyId, complaintData.title, complaintData.location);
          if (isDuplicate) {
            throw new Error("A similar issue was already reported in this society within the last 24 hours.");
          }
          result = await this.createComplaint(complaintData, userId, societyId);
          break;
        default:
          throw new Error(`Tool ${task.tool_id} not implemented`);
      }

      // 5. Mark Completed
      await this.updateStatus(actionId, "Completed");
      return result;
    } catch (error: any) {
      await this.updateStatus(actionId, "Failed", error.message);
      throw error;
    }
  }

  /**
   * AI V3.10: Society Analytics with Cache support.
   */
  public async getSocietyStats(societyId: string) {
    const cacheKey = `ai:stats:${societyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const db = getDb();
    
    // 1. Complaint Stats (Firestore)
    const issues = await db.collection("issues").where("society_id", "==", societyId).get();
    const complaints_count = issues.size;
    const open_complaints = issues.docs.filter((d: any) => d.data().status === "open").length;

    // 2. Notice Stats (Firestore - assuming they have society_id or postedBy)
    const notices = await db.collection("notices").where("society_id", "==", societyId).get();
    const notices_count = notices.size;

    // 3. AI Usage Stats (Postgres Audit Logs)
    const auditRes = await this.pool.query(
      `SELECT status, COUNT(*) FROM ai_audit_logs WHERE society_id = $1 GROUP BY status`,
      [societyId]
    );

    const stats = {
      complaints: { total: complaints_count, open: open_complaints },
      notices: { total: notices_count },
      ai_actions: auditRes.rows.reduce((acc: any, row: any) => {
        acc[row.status.toLowerCase()] = parseInt(row.count);
        return acc;
      }, {}),
      updatedAt: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 600, JSON.stringify(stats)); // 10 min cache
    return stats;
  }

  /**
   * AI V3.11: Proactive Society Digest Aggregator
   */
  public async getSocietyDigest(societyId: string) {
    const cacheKey = `ai:digest:${societyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const stats = await this.getSocietyStats(societyId);
    const finance = await this.analyzeExpenses(societyId);
    
    // Get latest processed AI jobs
    const db = getDb();
    const latestJobs = await db.collection("ai_jobs")
      .where("society_id", "==", societyId)
      .orderBy("updated_at", "desc")
      .limit(3)
      .get();

    const digest = {
      summary: `You have ${stats.complaints.open} open issues and ${stats.notices.total} active notices.`,
      insights: [
        stats.complaints.open > 5 ? "Issue volume is high. Consider sending a maintenance update." : "Issues are within normal range.",
        finance.totalSpent > 50000 ? `High spending detected this month (₹${finance.totalSpent.toLocaleString()}).` : "Spending is under control.",
        "AI is currently monitoring utility trends for anomalies."
      ],
      activeIndexing: latestJobs.docs.map((d: any) => ({
        file: d.data().file_name,
        status: d.data().status
      })),
      timestamp: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 1800, JSON.stringify(digest)); // 30 min cache
    return digest;
  }

  /**
   * AI V3.10: Financial Analysis Tool with Redis caching.
   */
  public async analyzeExpenses(societyId: string) {
    const cacheKey = `ai:finance:${societyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const sql = `
      SELECT category, SUM(ABS(amount)) as total, COUNT(*) as count 
      FROM fund_transactions 
      WHERE society_id = $1 AND amount < 0
      GROUP BY category
      ORDER BY total DESC
    `;
    const res = await this.pool.query(sql, [societyId]);

    const analysis = {
      categories: res.rows.map((row: any) => ({
        name: row.category,
        amount: parseFloat(row.total),
        frequency: parseInt(row.count)
      })),
      totalSpent: res.rows.reduce((sum: number, row: any) => sum + parseFloat(row.total), 0),
      topCategory: res.rows[0]?.category || "None",
      analyzedAt: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 600, JSON.stringify(analysis));
    return analysis;
  }

  private checkPermissions(tool: string, role: string) {
    if (tool === "create_notice" && !["admin", "main_admin", "secretary"].includes(role)) {
      throw new Error("Only Secretary or Admin can post notices.");
    }
    if (tool === "log_expense" && !["admin", "main_admin", "treasurer"].includes(role)) {
      throw new Error("Only Treasurer or Admin can log expenses.");
    }
    // Residents are allowed to create complaints
    if (tool === "create_complaint" && !["admin", "main_admin", "secretary", "resident"].includes(role)) {
       throw new Error("Not authorized to report issues.");
    }
  }

  private async recentSimilarIssueExists(societyId: string, title: string, location?: string): Promise<boolean> {
    const db = getDb();
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    // Check by title (semantic similarity is handled by prompt, but we do exact check here)
    const titleMatch = await db.collection("issues")
      .where("society_id", "==", societyId)
      .where("title", "==", title)
      .where("createdAt", ">", twentyFourHoursAgo)
      .limit(1)
      .get();

    if (!titleMatch.empty) return true;

    // Check by location if provided
    if (location) {
      const locMatch = await db.collection("issues")
        .where("society_id", "==", societyId)
        .where("location", "==", location)
        .where("status", "==", "open")
        .limit(1)
        .get();
      
      if (!locMatch.empty) return true;
    }

    return false;
  }

  private async updateStatus(actionId: string, status: string, error?: string) {
    const sql = `UPDATE ai_audit_logs SET status = $1, error_message = $2 WHERE action_id = $3`;
    await this.pool.query(sql, [status, error || null, actionId]);
  }

  // --- Actual Tool Implementations ---

  private async createNotice(data: z.infer<typeof NoticeSchema>, userId: string) {
    const db = getDb();
    const docRef = await db.collection("notices").add({
      ...data,
      postedBy: userId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    return { id: docRef.id, message: "Notice posted successfully" };
  }

  private async logExpense(data: z.infer<typeof ExpenseSchema>, userId: string, societyId: string) {
    // Insert into PostgreSQL funds/transactions table
    const sql = `
      INSERT INTO fund_transactions (title, description, amount, category, society_id, created_at, created_by)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id;
    `;
    const res = await this.pool.query(sql, [
      data.vendor,
      data.note || `Expense for ${data.vendor}`,
      -1 * data.amount,
      data.category,
      societyId,
      data.date,
      userId
    ]);
    return { id: res.rows[0].id, message: "Expense logged successfully" };
  }

  private async createComplaint(data: z.infer<typeof ComplaintSchema>, userId: string, societyId: string) {
    const db = getDb();
    const docRef = await db.collection("issues").add({
      ...data,
      society_id: societyId,
      postedBy: userId,
      status: "open",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      updatedAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    return { id: docRef.id, message: "Issue reported successfully" };
  }
}
