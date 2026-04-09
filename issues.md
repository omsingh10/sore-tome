# Current Architectural & Linting Issues

This document tracks technical debt, linting warnings, and deprecated API usage identified during the "The Sero" premium overhaul.

## Static Analysis Summary (Flutter Analyze) - 2026-04-04

### 1. Deprecated Member Usage
- **`withOpacity`**: System-wide migration to `.withValues(alpha: ...)` is **✅ Completed** for core modules to align with Flutter 3.27+.
- **`print`**: Systematic migration to `debugPrint()` is **✅ Completed** to ensure production-safe logging.

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

### 7. Billing API & Financial Integrity
- **Issue**: Persistent 500 errors and missing `GET` endpoints in the backend billing system.
- **Solution**: Implemented missing endpoints, added JPA Optimistic Locking for transaction safety, and hardened RBAC for treasurer roles.
- **Status**: ✅ Resolved.

### 8. AI "Financial Hallucinations"
- **Issue**: AI concierge providing inaccurate data regarding society funds based on static documents.
- **Solution**: Bridged real-time Firestore financial metrics into the AI context (Data Grounding).
- **Status**: ✅ Resolved.

---

## 🏗️ Remaining Infrastructure Debt (Updated)

While the Core UX is now stable and modular, the following technical goals remain:

### 1. Automated Late Fee Interest Engine
- **Problem**: Logic currently lacks a scheduled worker to calculate and apply interest/penalties to overdue resident accounts.
- **Priority**: High (Immediate Backend focus).

### 2. Financial Ledger Migration
- **Problem**: Current financial transactions live in Firestore. For ACID compliance and complex reporting, we need to migrate these to PostgreSQL.
- **Priority**: Medium.

### 3. PDF Reporting Microservice
- **Problem**: Society committees require standardized PDF reports for monthly financial meetings.
- **Priority**: Medium.

### 4. Real-Time Message Synchronization
- **Problem**: Minor latency issues in "Message Delivery Ticks" between backend processing and frontend UI updates.
- **Priority**: Low (Polish).

---

## ✅ Updated Priority Fixes Roadmap

### Frontend
- [x] Migrate remaining 50+ `withOpacity` to `withValues`.
- [x] Modernize logging with `debugPrint()`.
- [ ] Implement a "Retry" button for failed AI Ingestion tasks in the Admin Console.
- [ ] Build the **Society AI Analytics Header** (Tokens used, Docs indexed).

### Backend
- [x] Stabilize Billing API (GET endpoints & Optimistic Locking).
- [x] Bridge Firestore financial metrics to AI context.
- [ ] Build the `/ai/usage/stats` endpoint to feed the new Admin header.
- [ ] Transition Tesseract.js (WASM) to a dedicated server-side microservice for faster batch processing.
- [ ] Implement **Automated Late Fee** scheduled worker.
