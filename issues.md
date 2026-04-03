# Current Architectural & Linting Issues

This document tracks technical debt, linting warnings, and deprecated API usage identified during the "The Sero" premium overhaul.

## Static Analysis Summary (Flutter Analyze) - 2026-04-03

### 1. Deprecated Member Usage (38 Issues)
Most of these are related to the transition to Flutter 3.22+ and require migration to modern equivalents:
- **`withOpacity`** is deprecated. Recommendation: Use `.withValues(alpha: ...)` or `Color.fromARGB/fromRGBA`.
    - `lib/screens/ai_chat/ai_chat_screen.dart`: Lines 268, 341, 465, 495, 516, 519...
    - `lib/screens/funds/funds_screen.dart`: Lines 246, 383...
- **`Radius.circular` / `BorderRadius`** usage in some areas flagged for potential precision loss.

### 2. Async Safety (12 Issues)
**Rule: `use_build_context_synchronously`**
Multiple screens are performing `async` operations (Firestore/AI requests) and then calling `setState` or navigating without checking `if (!mounted)`.
- `lib/screens/ai_chat/ai_chat_screen.dart`: Within the `_send` logic.
- `lib/screens/funds/funds_screen.dart`: Within the `_load` logic.

### 3. Layout & Widget Quality (4 Issues)
- **Hardcoded Colors**: Some widgets are still using `Color(0xFF...)` instead of the centralized `kPrimaryGreen` or `kSlateBg` from `app/theme.dart`.
- **Text Styling**: Some `Text` widgets ARE NOT using `GoogleFonts.outfit`, which breaks brand consistency.

## Priority Fixes Needed
- [ ] Migrate all `withOpacity` to `withValues` to future-proof the "The Sero" graphics engine.
- [ ] Implement `mounted` checks for all AI and Firestore service calls.
- [ ] Extract remaining hardcoded branding colors to `theme.dart`.
