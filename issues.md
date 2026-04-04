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

## Priority Fixes Needed
- [ ] Migrate all `withOpacity` to `withValues` to future-proof the "The Sero" graphics engine (High Priority).
- [ ] Implement `mounted` checks for all AI, Firestore, and Auth service calls.
- [ ] Extract remaining hardcoded branding colors to `theme.dart`.
- [ ] Fix persistent linting markers in `lib/main.dart`.
