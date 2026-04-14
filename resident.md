# The Sero - Resident Experience Development Log

This document summarizes all technical and UI/UX enhancements implemented for the **Resident** persona of "The Sero" society application.

## 1. Onboarding & Account Management
- **Smart Registration**: 
    - Simplified sign-up flow capturing Name, Phone, Flat Number, and Block.
    - Automatic role assignment (`resident`) with secondary `residentType` flags (`owner`, `tenant`, or `guest`).
- **Approval Lifecycle**: 
    - Implementation of the **`PendingApprovalScreen`**: A graceful waiting state providing high-contrast visual feedback while residents await admin validation.
- **Security Hardening**:
    - **Brute-Force Protection**: Residents are protected by progressive delays and account lockouts to prevent credential stuffing.
    - **Session Resilience**: Use of rotating refresh tokens ensuring resident sessions remain secure on mobile devices.

## 2. Sero Concierge AI (Resident Mode)
The AI assistant has been specifically tailored to serve as a high-fidelity digital concierge for residents.
- **Domain Specialization**: 
    - Trained on the society’s specific rules, facilities, and timings.
    - Acts as the first point of contact for "How do I...?" or "Where is...?" queries.
- **Assisted Complaint Generation**:
    - Residents can use the AI to draft detailed maintenance or security complaints.
    - The AI automatically categorizes the issue and suggests a priority level based on the description.
- **UI Enhancements**:
    - **Suggestion Chips**: Scrolling horizontal chips for one-tap resident queries (e.g., "Guest Parking Rules", "Clubhouse Booking").
    - **Branded Interaction**: Unique AI identity utilizing robot icons and conversational, helpful tones.

## 3. Communication Hub & Community
- **Channel Access**: 
    - Full access to community discussion channels with real-time Firestore syncing.
    - Branded message bubbles with unread counts and snippet previews.
- **Official Notices**: 
    - A read-only stream of society announcements, ensuring critical information is never missed.
- **Social Commerce (Group Deals)**: 
    - Residents can participate in "Group deals" where bulk discounts are triggered once a target number of residents join a deal (implemented in `channels.js`).

## 4. Maintenance & Issue Tracking (Deep Dive)
- **Status Ecosystem**: 
    - Real-time tracking of lifecycle states: `open` ➔ `in_progress` ➔ `resolved`. 
    - Includes `adminNote` feedback loop for resident closure.
- **Reporting Intelligence**:
    - All reports are validated via [CreateIssueSchema](file:///e:/Work/sore-tome/society-backend/src/shared/schemas.ts).
    - Features strict sanitization: title (trimmed, max 150), description (trimmed, max 2000).
- **Security & Privacy (IDOR Masking)**:
    - **Implementation**: `if (!isOwner && !isAdmin) return res.status(404)`.
    - **Logic**: Unauthorized attempts to access private issues are met with a "Not Found" response instead of a "Forbidden" response. This prevents attackers from verifying the existence of specific complaint IDs.
    - **Visibility**: Backend selectively joins the resident's own issues with society-wide `open` issues using parallelized Firestore queries (`Promise.all`).

## 5. Sero Concierge AI - Engineering Details
- **Triage Logic**: 
    - Integrated with the `CreateIssueSchema`. When a resident says *"There is a leak in the basement"*, the AI automatically maps this to `category: "maintenance"` and `priority: "high"`.
- **Personality Grounding**: 
    - Hard-coded system prompt: *"You are Sero Concierge. You help residents with questions about society rules, timings, events, and facilities. You are polite, professional, and safety-conscious."*
- **Mobile Interaction**:
    - **Suggestion Chips**: Dynamically injected based on recent society notifications or frequently asked resident questions.

## 6. Financial Transparency & Integrity
- **Personal Ledger**: 
    - Real-time view of individual maintenance dues and payment history.
- **Strict Validation**: 
    - All financial interactions utilize `.strict()` mode in Zod, rejecting any unknown parameters to prevent "parameter pollution" attacks during payment logging.

## 7. Security Infrastructure (Resident Protection)
- **Account Shield**: 
    - Implementation of progressive delays (5s to 30s) to protect resident accounts from credential stuffing.
- **Alerting Integration**: 
    - Suspicious resident-side actions (like multiple failed valid signature attempts) trigger a `SEC-SIGNAL [WARN]` in the [SecurityAlertService](file:///e:/Work/sore-tome/society-backend/src/services/SecurityAlertService.ts).

## 8. Mobile Performance & UX
- **Identity & Branding**: 
    - Consistent application of the "Dark Emerald" theme across all resident screens.
- **Staggered Animations**: 
    - Use of `flutter_animate` for a premium, non-static experience during data loading.
- **Identity & Branding**: 
    - Consistent application of the "Dark Emerald" theme across all resident screens.
    - High-fidelity typography using `GoogleFonts.outfit`.
- **Optimized Scrolling**: 
    - Implementation of FAB-safe padding (120dp) to ensure resident list items are never obscured by action buttons.
    - Use of `flutter_animate` to provide a premium feel when transitioning between house rules, dashboards, and financial summaries.

---
*Last Updated: April 14, 2026*
