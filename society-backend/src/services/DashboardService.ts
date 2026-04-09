// @ts-ignore
import { getDb, getAdmin } from "../../config/firebase";
import { Pool } from "pg";
import IORedis from "ioredis";
import { logger } from "../shared/Logger";

export class DashboardService {
  private static instance: DashboardService;
  private pool: Pool;
  private redis: IORedis;

  private constructor() {
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL });
    this.redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");
  }

  public static getInstance(): DashboardService {
    if (!DashboardService.instance) {
      DashboardService.instance = new DashboardService();
    }
    return DashboardService.instance;
  }

  public async getDashboardStats(societyId: string) {
    const cacheKey = `admin:dashboard:${societyId}`;
    
    // Attempt cache fetch
    try {
      const cached = await this.redis.get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (e) {
      logger.warn("Redis unreachable, fetching from source.");
    }

    const db = getDb();
    const admin = getAdmin();

    // 1. Fetch Pending Approvals Count
    const pendingSnap = await db.collection("users")
      .where("status", "==", "pending")
      .get();
    const pendingApprovalsCount = pendingSnap.size;

    // 2. Fetch Top Issues (Sorted by Priority)
    // Priority order: high -> medium -> low
    const issuesSnap = await db.collection("issues")
      .where("status", "==", "open")
      .limit(10) // Fetch more to manually sort if needed
      .get();
    
    const priorityMap: Record<string, number> = { high: 3, medium: 2, low: 1 };
    const topIssues = issuesSnap.docs
      .map((doc: any) => {
        const data = doc.data();
        return { 
          id: doc.id, 
          ...data,
          priority: data.priority || 'medium' // Default for old data
        };
      })
      .sort((a: any, b: any) => (priorityMap[b.priority] || 0) - (priorityMap[a.priority] || 0))
      .slice(0, 3);

    // 3. Recent Updates (Combined Notices & Events)
    const noticesSnap = await db.collection("notices")
      .orderBy("createdAt", "desc")
      .limit(3)
      .get();
    
    const eventsSnap = await db.collection("events")
      .orderBy("createdAt", "desc")
      .limit(3)
      .get();

    const recentUpdates = [
      ...noticesSnap.docs.map((d: any) => ({ type: 'notice', id: d.id, ...d.data() })),
      ...eventsSnap.docs.map((d: any) => ({ type: 'event', id: d.id, ...d.data() }))
    ].sort((a: any, b: any) => {
        const timeA = a.createdAt?.toDate()?.getTime() || 0;
        const timeB = b.createdAt?.toDate()?.getTime() || 0;
        return timeB - timeA;
    }).slice(0, 4);

    // 4. Financial Summary (Firestore)
    // V3.10: Using Firestore transactions instead of Postgres until formal migration
    const transSnap = await db.collection("transactions").get();
    let totalCollected = 0;
    let totalSpent = 0;
    transSnap.forEach((doc: any) => {
      const d = doc.data();
      if (d.type === "credit") totalCollected += d.amount;
      if (d.type === "debit") totalSpent += d.amount;
    });

    // 5. Society Settings (Target & Currency)
    const settingsSnap = await db.collection("society_settings").doc("global").get();
    const settings = settingsSnap.exists ? settingsSnap.data() : { target: 200000, currency: "Rs" };
    const target = settings.target > 0 ? settings.target : 1; // Prevent division by zero

    // 6. Active Residents (On-Site Count)
    const activeResidentsSnap = await db.collection("users")
      .where("status", "==", "approved")
      .get();
    const activeResidentsCount = activeResidentsSnap.size;

    const stats = {
      pendingApprovalsCount,
      topIssues,
      recentUpdates,
      financials: {
        totalCollected,
        totalSpent,
        balance: totalCollected - totalSpent,
        target: settings.target,
        currency: settings.currency,
        percentage: Math.min(100, Math.round((totalCollected / target) * 100))
      },
      activeResidentsCount,
      updatedAt: new Date().toISOString()
    };

    await this.redis.setex(cacheKey, 300, JSON.stringify(stats)); // 5 min cache
    return stats;
  }
}
