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

## 🚀 Resolved Issues (Backend AI)

### 1. Synchronous Thread Blocking
- **Issue**: Heavy AI tasks (PDF ingestion) were blocking the Express event loop.
- **Solution**: Implemented `AIQueueService` using **BullMQ + Redis**. Jobs are now processed by background workers with 5x concurrency.
- **Status**: ✅ Fixed

### 2. Output Formatting Instability
- **Issue**: LLMs occasionally returned malformed or "Markdown-wrapped" JSON, causing `JSON.parse` to crash.
- **Solution**: Added `safeParseAIResponse` with Regex sanitization and **Zod** schema validation in extraction routes.
- **Status**: ✅ Fixed

### 3. Slow OCR / Attachment Timeouts
- **Issue**: Large image attachments caused chat requests to hang or time out at the Load Balancer level.
- **Solution**: Implemented a **10-second timeout** using `Promise.race` in `AIChatService.ts`. The system now continues with a "best effort" text-only response if OCR fails.
- **Status**: ✅ Fixed

### 4. SSE Streaming Reliability
- **Issue**: Slow LLM providers caused Server-Sent Events (SSE) to hang indefinitely.
- **Solution**: Added a **7-second watchdog timer** that sends a "System busy, retrying..." message and closes the stream if no chunk is received.
- **Status**: ✅ Fixed

## 🛠️ Current Backend AI Infrastructure Debt

The backend's Resilient AI Gateway is currently operational but requires the following structural fixes:

### 1. Vector Metadata Isolation Safety (Critical)
- **Problem**: Potential for cross-tenant data leakage if the chunking pipeline drops the `society_id`.
- **Recommendation**: Enforce rigid, mandatory `society_id` assertions at the Document Metadata level in `VectorStoreService`.

### 2. Lack of Background Task Visibility (UX)
- **Problem**: Societies can trigger ingestion via `/ai/ingest`, but there is no UI/API to check the status of their specific background job.
- **Recommendation**: Create a `/ai/tasks/status/:jobId` endpoint and a Flutter "Task Progress" widget.

### 3. LLM Auto-Repair Loop
- **Problem**: When `safeParseAIResponse` fails, we currently fall back to plain text.
- **Recommendation**: Implement a recursive "Refinement Loop" where the AI is given the error and asked to fix the JSON structure once before failing.

### 4. Handwriting & Table OCR Accuracy
- **Problem**: Tesseract (WASM-based) struggles with handwritten documents or complex financial tables.
- **Recommendation**: Investigate a "Hybrid OCR" strategy: Tesseract for standard text, and **GPT-4o-Vision** (as a fallback) for complex structural extraction.

## ✅ Priority Fixes Needed

### Frontend
- [ ] Migrate all `withOpacity` to `withValues` (High Priority).
- [ ] Implement `mounted` checks for all async service calls.
- [ ] Extract remaining hardcoded branding colors to `theme.dart`.

### Backend
- [ ] Hardcode metadata assertions for `society_id` in pgvector pipelines.
- [ ] Build `/ai/tasks/status` endpoint for background job tracking.
- [ ] Implement "Hybrid OCR" for complex document extraction.
- [ ] Build a per-society AI token usage/quota dashboard.
