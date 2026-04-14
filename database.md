# Sero Society: Database & System Architecture Documentation

## 🛠️ Technology Stack

The Sero Society backend uses a **Polyglot Persistence** strategy to optimize for real-time interaction, complex search, and reliable caching.

| Technology | Role | Use Case |
| :--- | :--- | :--- |
| **PostgreSQL** | Primary Relational DB | Hybrid Search (Semantic + FTS), AI Audit Logs, and Cost Tracking. |
| **Firestore** | Real-time NoSQL | Operational data (Users, Issues, Funds, Channels) requiring low-latency listener support. |
| **Redis** | In-Memory Store | Distributed Locks (SETNX), Dashboard Caching, and session management. |
| **Knex.js** | Schema Manager | Managed migrations and structured query building for PostgreSQL. |
| **BullMQ** | Background Jobs | Async referential integrity (Cascading deletes) and cleanup tasks. |
| **pgvector** | Vector Search | Advanced AI document chunking and semantic similarity search. |

---

## 🚀 Phase 2.5: Database & System Architecture Hardening (Completed)

Current Maturity: ✅ **PRODUCTION READY**

### Accomplishments Summary

#### 1. Multi-Tenancy (Double-Layer Defense)
*   **Layer 1 (Middleware)**: Implemented `tenantMiddleware.js` to automatically extract `societyId` from the JWT and inject it into every request.
*   **Layer 2 (Logic)**: Refactored `DashboardService`, `issues.js`, `funds.js`, and `channels.js` to strictly filter by `societyId` at the query level (PostgreSQL and Firestore).

#### 2. PostgreSQL Hardening
*   **Managed Schema**: Transitioned from dynamic table creation to **Knex.js** for version-controlled, reversible migrations.
*   **Performance Optimization**: Added a top-level `society_id` column and B-Tree index to `document_chunks`, significantly accelerating hybrid search.
*   **Observability**: Implemented **Slow Query Monitoring** in `Database.ts`. Queries exceeding 500ms are logged with a `WARN` flag for proactive tuning.

#### 3. Redis & Cache Resilience
*   **Distributed Locking**: Implemented `SETNX` locking with auto-extension in `AICostService.ts` to prevent "Cache Stampedes."
*   **PG Fallback**: Added a reliable PostgreSQL fallback path to ensure data availability even if Redis is fluctuating.

#### 4. Data Migration & Integrity
*   **Firestore Backfill**: Partitioned all legacy records into their respective societies via indexed mapping (Audit log: `firestore_backfill_audit.json`).
*   **Async Cleanup**: Established a **BullMQ** worker framework (`CleanupWorker.ts`) for background referential integrity tasks (e.g., cascading deletions).

---

## 📂 Detailed File Changes & Rationale

| File Path | Change | Rationale (Why?) |
| :--- | :--- | :--- |
| `knexfile.js` | **[NEW]** Knex configuration | Establishes a standard for managed database migrations across dev/prod environments. |
| `migrations/*.js` | **[NEW]** Migrations for `society_id`, Indexing, and AI Tables | Moves schema control from application logic to versioned files, allowing for zero-downtime evolution. |
| `middleware/tenantMiddleware.js` | **[NEW]** Tenant Injection Layer | Centralizes the multi-tenancy logic. If a request is missing a `societyId`, it is blocked before hitting any services. |
| `src/shared/Database.ts` | **[MOD]** Added Observability Wrapper | Wraps the query pool to track execution time. This is critical for catching performance regressions early. |
| `src/services/ai/VectorStoreService.ts` | **[MOD]** Hybrid Search SQL Update | Switched from expensive JSONB metadata scans to an indexed column search using `COALESCE` for backward compatibility. |
| `src/services/ai/AICostService.ts` | **[MOD]** Distributed Locking & Fallback | Prevents multiple servers from hammering the DB to rebuild the same cache key simultaneously. |
| `routes/issues.js` \| `funds.js` \| `channels.js` | **[MOD]** Server-side Filtering | Replaced client-side `.filter()` with Firestore `.where("societyId", "==")`. Reduces billing and improves security. |
| `src/services/DashboardService.ts` | **[MOD]** Tenant Isolation | Ensures admins only see statistics, issues, and funds belonging to their specific society. |
| `src/workers/CleanupWorker.ts` | **[NEW]** Referential Integrity Workers | Offloads heavy cleanup operations (deleting media/notifs) to a background queue to ensure fast response times. |
| `firestore.rules` | **[NEW]** Infrastructure Security Layer | Last line of defense. Denies any read/write request that doesn't match the user's `societyId` claim. |

---

## 📈 Search Performance Comparison

| Search Strategy | Time Complexity | Performance |
| :--- | :--- | :--- |
| **Old (JSONB Metadata)** | $O(N)$ - Full Table Scan | 🐌 Slows down linearly as data grows. |
| **New (Indexed Column)** | $O(\log N)$ - B-Tree Index | ⚡ Instant search even with millions of chunks. |

---
> [!IMPORTANT]
> All future database structural changes must be done via `npx knex migrate:make`.
> All future Firestore collections must include a `societyId` field for proper partitioning.
