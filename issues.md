# Current Architectural & Linting Issues

This document tracks technical debt, linting warnings, and deprecated API usage identified during the "The Sero" premium overhaul.

## Static Analysis Summary (Flutter Analyze) - 2026-04-04

### 1. Deprecated Member Usage (56 Issues)
The issue count has increased from 38 to 56, primarily due to the addition of more UI components and Screens:
- **`withOpacity`** is deprecated across almost every screen.
    - `lib/screens/auth/pending_approval_screen.dart`: Lines 150...
    - `lib/main.dart`: Line 8...
- **Recommendation**: System-wide migration to `.withValues(alpha: ...)` is now high priority to avoid precision loss.

### 2. Async Safety (14 Issues)
**Rule: `use_build_context_synchronously`**
- Two new async checks identified in the auth flow. Need `if (!mounted)` checks before navigation in `pending_approval_screen.dart` and `auth_guard.dart`.

### 3. Layout & Widget Quality (4 Issues)
- **Hardcoded Colors**: Still persisting in newer screens (Auth related).
- **Text Styling**: Some `Text` widgets in the "Pending Approval" UI require `GoogleFonts.outfit` for consistency.

## Priority Fixes Needed (Frontend)
- [ ] Migrate all `withOpacity` to `withValues` to future-proof the "The Sero" graphics engine (High Priority).
- [ ] Implement `mounted` checks for all AI, Firestore, and Auth service calls.
- [ ] Extract remaining hardcoded branding colors to `theme.dart`.
- [ ] Fix persistent linting markers in `lib/main.dart`.

## Backend AI Infrastructure Debt

The backend's Resilient AI Gateway is currently operational but requires the following structural fixes to ensure true production readiness and prevent server bottlenecks:

### 1. Synchronous Thread Blocking (High Priority)
- **Problem**: Heavy batch AI extractions (like parsing multi-page PDF rulebooks) are processed on the main Node.js event loop, blocking standard HTTP requests.
- **Recommendation**: Wire the `AIQueueService` with **Redis + BullMQ** to offload heavy Langchain execution to asynchronous background workers.

### 2. Output Formatting Instability (Medium Priority)
- **Problem**: Fallback LLMs occasionally hallucinate malformed JSON when processing complex extractions, causing database insertion errors.
- **Recommendation**: Implement strict **Zod** schema validation inside `AIExtractionService` to sanitize and ensure exact data structures.

### 3. Missing Cascading Circuit Breakers (Medium Priority)
- **Problem**: The AI fallback mechanism waits for full network timeouts (often up to 30s) before failing over to the next LLM provider (e.g., Groq -> Cerebras), causing poor UX during upstream disruptions.
- **Recommendation**: Implement Redis-backed "circuit breakers" to instantly bypass any failing Langchain provider for ~10 seconds after a detected failure.

### 4. Vector Metadata Isolation Safety (Critical)
- **Problem**: Cross-tenant data leakage is theoretically possible if the pgvector chunking pipeline drops or omits the `society_id`.
- **Recommendation**: Enforce rigid, mandatory `society_id` assertions at the Document Metadata level before any `VectorStoreService` insertion.

## Priority Fixes Needed (Backend)
- [ ] Implement Redis + BullMQ background task queue for AI document extraction.
- [ ] Add Zod validation schemas to sanitize all LLM JSON generation.
- [ ] Build custom API circuit breakers for the AI Provider Mesh.
- [ ] Hardcode metadata assertions for `society_id` in pgvector pipelines.
