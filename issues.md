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

---

## 🚀 Resolved Issues & Technical Debt (Refactoring & AI)

Since the last audit, we have successfully resolved several critical architectural bottlenecks:

### 1. Monolithic Screen Congestion
- **Issue**: Six core screens (`AI Chat`, `Funds`, `Admin Users`, `Admin Channels`, `Admin Home`, `Issues`) were 500-1,800 lines long, making maintenance high-risk.
- **Solution**: Executed a **Massive Modularization Overhaul**, extracting 80-90% of UI logic into thematic `widgets/` directories.
- **Status**: ✅ Completed. Core screens are now <200 lines each.

### 2. Lack of Ingestion Visibility (UX)
- **Issue**: Admins could trigger document ingestion but had no way to track progress or verify if a 50-page PDF was indexed.
- **Solution**: Built a real-time **AI Ingestion Console** in the Admin dashboard synced to a Firestore `ai_jobs` stream fueled by **BullMQ**.
- **Status**: ✅ Completed. Live progress bars and status chips (Indexed/Failed) are operational.

### 3. FilePicker (v11) API Breakage
- **Issue**: The `.platform` getter was removed in a package update, causing a complete build failure.
- **Solution**: Migrated all instances (e.g., `AdminAIScreen:41`) to the new static `FilePicker.pickFiles()` API.
- **Status**: ✅ Fixed.

### 4. Unsafe Async BuildContext Usage
- **Issue**: Multiple `use_build_context_synchronously` warnings were present in the AI Chat and Funds modules.
- **Solution**: Hardened all async gaps with `if (!context.mounted) return;` checks to prevent potential crashes on high-latency API responses.
- **Status**: ✅ Fixed.

### 5. Deprecated `DropdownButtonFormField` Properties
- **Issue**: Use of the deprecated `value` property was causing framework-level linting warnings.
- **Solution**: Migrated all core form fields to use `initialValue` as per Flutter 3.33+ standards.
- **Status**: ✅ Fixed.

### 6. Android Build Cache/Root Conflict
- **Issue**: "this and base files have different roots" Gradle error due to E: vs C: drive mismatch.
- **Solution**: Orchestrated systematic `flutter clean` and cache wipe for the **E:** drive mount.
- **Status**: ✅ Resolved.

---

## 🏗️ Remaining Infrastructure Debt (Updated)

While the Core UX is now stable and modular, the following technical goals remain:

### 1. Vector Metadata Assertion (Hardening)
- **Problem**: We need "Double-Lock" security to ensure `society_id` is never dropped during the pgvector embedding pipeline.
- **Recommendation**: Implement a formal **Guardrail Middleware** in `VectorStoreService` that throws a 500 if a chunk is missing its tenant tag.

### 2. Standardized `withValues` Migration
- **Problem**: 50+ instances of the deprecated `.withOpacity()` still exist in the auth and profile screens.
- **Priority**: Medium.

### 3. Per-Society Usage Dashboard
- **Problem**: Administrators currently lack a way to see their AI token consumption vs. their billing tier.
- **Priority**: High (Next Phase).

---

## ✅ Updated Priority Fixes Roadmap

### Frontend
- [ ] Migrate remaining 50+ `withOpacity` to `withValues`.
- [ ] Implement a "Retry" button for failed AI Ingestion tasks in the Admin Console.
- [ ] Build the **Society AI Analytics Header** (Tokens used, Docs indexed).

### Backend
- [ ] Hardcode strict `society_id` assertions in the ingestion pipeline.
- [ ] Build the `/ai/usage/stats` endpoint to feed the new Admin header.
- [ ] Transition Tesseract.js (WASM) to a dedicated server-side microservice for faster batch processing.
