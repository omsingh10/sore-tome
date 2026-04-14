import { z } from "zod";
// @ts-ignore
import { getDb, getAdmin } from "../../../config/firebase";
import { VectorStoreService } from "./VectorStoreService";
import { logger } from "../../shared/Logger";
import { db } from "../../shared/Database";
import { redis } from "../../shared/Redis";
import crypto from "crypto";

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
  private pool = db;
  private redis = redis;
  private isPostgresAvailable: boolean = true;
  private isRedisAvailable: boolean = true;
  private lastNetworkError: number = 0;

  private constructor() {
    // V3.12: Infrastructure initialization moved to shared singleton clients
    // Redundant heartbeat loops removed to prevent connection exhaustion.
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
          result = await this.createNotice(noticeData, userId, societyId);
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
    const targetSocietyId = societyId || "main_society";
    const cacheKey = `ai:stats:${targetSocietyId}`;
    if (!this.isRedisAvailable) return null; // Graceful skip
    try {
      const cached = await this.redis.get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (e) {
      this.isRedisAvailable = false;
      return null;
    }

    const db = getDb();
    
    // 1. Complaint Stats (Firestore)
    const issues = await db.collection("issues").where("society_id", "==", targetSocietyId).get();
    const complaints_count = issues.size;
    const open_complaints = issues.docs.filter((d: any) => d.data().status === "open").length;

    // 2. Notice Stats (Firestore - assuming they have society_id or postedBy)
    const notices = await db.collection("notices").where("society_id", "==", targetSocietyId).get();
    const notices_count = notices.size;

    // 3. AI Usage Stats (Postgres Audit Logs)
    const auditRes = await this.pool.query(
      `SELECT status, COUNT(*) FROM ai_audit_logs WHERE society_id = $1 GROUP BY status`,
      [targetSocietyId]
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
    const targetSocietyId = societyId || "main_society";
    const cacheKey = `ai:digest:${targetSocietyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const stats = await this.getSocietyStats(targetSocietyId);
    const finance = await this.analyzeExpenses(targetSocietyId);
    
    // Get latest processed AI jobs
    const db = getDb();
    // V3.12: Fetch without orderBy to avoid composite index requirement
    // We fetch a larger batch and sort in-memory
    const jobsSnap = await db.collection("ai_jobs")
      .where("society_id", "==", targetSocietyId)
      .limit(10) 
      .get();

    const sortedJobs = jobsSnap.docs
      .map((d: any) => ({
        id: d.id,
        ...d.data()
      }))
      .sort((a: any, b: any) => {
        const dateA = a.updated_at?.toDate?.() || new Date(a.updated_at);
        const dateB = b.updated_at?.toDate?.() || new Date(b.updated_at);
        return dateB - dateA;
      })
      .slice(0, 3);

    const digest = {
      summary: `You have ${stats.complaints.open} open issues and ${stats.notices.total} active notices.`,
      insights: [
        stats.complaints.open > 5 ? "Issue volume is high. Consider sending a maintenance update." : "Issues are within normal range.",
        finance.totalSpent > 50000 ? `High spending detected this month (₹${finance.totalSpent.toLocaleString()}).` : "Spending is under control.",
        "AI is currently monitoring utility trends for anomalies."
      ],
      activeIndexing: sortedJobs.map((job: any) => ({
        file: job.file_name,
        status: job.status
      })),
      timestamp: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 300, JSON.stringify(digest)); // 5 min cache (V3.12 Optimized)
    return digest;
  }

  /**
   * AI V3.10: Financial Analysis Tool with Redis caching.
   */
  public async analyzeExpenses(societyId: string) {
    const targetSocietyId = societyId || "main_society";
    const cacheKey = `ai:finance:${targetSocietyId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const db = getDb();
    // Zero-Config: Use only society_id filter to utilize automatic single-field index.
    // Filtering for 'debit' type is performed in-memory.
    const transSnap = await db.collection("transactions")
      .where("society_id", "==", targetSocietyId)
      .get();

    const categoryMap: Record<string, { total: number, count: number }> = {};
    transSnap.docs.forEach((doc: any) => {
      const d = doc.data();
      if (d.type !== "debit") return; // In-memory filtering
      
      if (!categoryMap[d.category]) {
        categoryMap[d.category] = { total: 0, count: 0 };
      }
      categoryMap[d.category].total += d.amount;
      categoryMap[d.category].count += 1;
    });

    const analysis = {
      categories: Object.entries(categoryMap).map(([name, data]) => ({
        name,
        amount: data.total,
        frequency: data.count
      })).sort((a: any, b: any) => b.amount - a.amount),
      totalSpent: Object.values(categoryMap).reduce((sum, data) => sum + data.total, 0),
      topCategory: Object.keys(categoryMap).length > 0 ? 
        Object.entries(categoryMap).sort((a, b) => b[1].total - a[1].total)[0][0] : "None",
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
    
    // Zero-Config: Query by society_id only and filter details in-memory.
    const issuesMatch = await db.collection("issues")
      .where("society_id", "==", societyId)
      .get();

    const recentIssues = issuesMatch.docs.filter((doc: any) => {
      const data = doc.data();
      const createdAt = data.createdAt?.toDate?.() || new Date(data.createdAt);
      
      // Check title similarity (exact) for recent issues
      if (data.title === title && createdAt > twentyFourHoursAgo) return true;
      
      // Check location match for any open issue
      if (location && data.location === location && data.status === "open") return true;
      
      return false;
    });

    return recentIssues.length > 0;
  }

  private async updateStatus(actionId: string, status: string, error?: string) {
    const sql = `UPDATE ai_audit_logs SET status = $1, error_message = $2 WHERE action_id = $3`;
    await this.pool.query(sql, [status, error || null, actionId]);
  }

  // --- Actual Tool Implementations ---

  private async createNotice(data: z.infer<typeof NoticeSchema>, userId: string, societyId: string) {
    const db = getDb();
    const docRef = await db.collection("notices").add({
      ...data,
      society_id: societyId,
      postedBy: userId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    return { id: docRef.id, message: "Notice posted successfully" };
  }

  private async logExpense(data: z.infer<typeof ExpenseSchema>, userId: string, societyId: string) {
    // V3.10: Log to Firestore transactions instead of Postgres
    const db = getDb();
    const docRef = await db.collection("transactions").add({
      title: data.vendor,
      amount: data.amount,
      type: 'debit',
      category: data.category,
      note: data.note || "",
      society_id: societyId,
      addedBy: userId,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });
    return { id: docRef.id, message: "Expense logged to Firestore successfully" };
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
