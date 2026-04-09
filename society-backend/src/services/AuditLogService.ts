import { getDb, getAdmin } from "../../config/firebase";
import { logger } from "../shared/Logger";

export type LogType = 'administrative' | 'security' | 'system';

export interface AuditLogItem {
    type: LogType;
    action: string;
    actorId: string;
    actorName: string;
    details: string;
    metadata?: Record<string, any>;
    societyId: string;
    createdAt?: any;
}

export class AuditLogService {
    private static instance: AuditLogService;

    private constructor() {}

    public static getInstance(): AuditLogService {
        if (!AuditLogService.instance) {
            AuditLogService.instance = new AuditLogService();
        }
        return AuditLogService.instance;
    }

    /**
     * Creation of a new log entry
     */
    public async log(item: AuditLogItem): Promise<string> {
        try {
            const db = getDb();
            const admin = getAdmin();

            const logRef = await db.collection("audit_logs").add({
                ...item,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return logRef.id;
        } catch (err: any) {
            logger.error(`Failed to create audit log: ${err.message}`);
            return "";
        }
    }

    /**
     * Retrieval of logs with filtering
     */
    public async getLogs(societyId: string, type?: string, limit = 50) {
        try {
            const db = getDb();
            let query = db.collection("audit_logs")
                .where("societyId", "==", societyId)
                .orderBy("createdAt", "desc");

            if (type && type !== 'all') {
                query = query.where("type", "==", type);
            }

            const snap = await query.limit(limit).get();
            
            return snap.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : new Date().toISOString()
                };
            });
        } catch (err: any) {
            logger.error(`Failed to fetch audit logs: ${err.message}`);
            return [];
        }
    }

    // Convenience helpers
    public async logAdminAction(actor: any, action: string, details: string, metadata?: any) {
        return this.log({
            type: 'administrative',
            action,
            actorId: actor.uid,
            actorName: actor.name || 'Admin',
            details,
            metadata,
            societyId: 'global' // Defaulting to global since we only have one society for now
        });
    }

    public async logSecurityEvent(actorName: string, action: string, details: string, metadata?: any) {
        return this.log({
            type: 'security',
            action,
            actorId: 'system',
            actorName,
            details,
            metadata,
            societyId: 'global'
        });
    }
}
