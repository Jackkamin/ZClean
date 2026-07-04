# ZClean iOS App - Review Brief

## What this project is

`ZClean` is a lean SwiftUI + SwiftData iPhone app for a solo cleaner.

Primary daily loop:

1. Add job or record instant payment
2. Collect payment from upcoming jobs
3. See current-month earnings update
4. Exit

The app intentionally avoids heavy setup/onboarding and complex admin features.

---

## Tech stack

- SwiftUI
- SwiftData
- UserNotifications (local reminders)
- CryptoKit + Keychain (encrypted client names)

---

## Current feature set

- Dashboard with:
  - This month total
  - Upcoming jobs (with collect action)
  - Recent payments preview (latest 3)
- Quick Add sheet (segmented mode):
  - Add Job
  - Get Paid
- Edit Jobs screen:
  - View all upcoming jobs (including weekly jobs hidden from dashboard due to 24h rule)
  - Edit / delete jobs
- Collect payment flow:
  - Confirmation alert
  - Center confirmation animation ("Payment Sent")
  - This month total count-up animation
- Weekly jobs:
  - Optional recurrence
  - Select repeat weekdays
  - Recurrence editable later
  - Next recurring job auto-created when collecting payment
  - Weekly jobs only appear on dashboard within 24h of scheduled time
- More/history:
  - Recent section on dashboard + full history screen
- Notifications:
  - 1 hour before scheduled job
  - 9:00 AM fallback if no time
- Security:
  - Client names encrypted with Keychain-backed key
  - Fallback handling to avoid save failures if keychain edge cases occur

---

## Main paths/files

- App entry:
  - `ZClean/ZClean/ZCleanApp.swift`
- Dashboard and core logic:
  - `ZClean/ZClean/Features/Dashboard/DashboardView.swift`
  - `ZClean/ZClean/Features/Dashboard/JobRowView.swift`
- Add/edit/collect flows:
  - `ZClean/ZClean/Features/Jobs/QuickAddSheet.swift`
  - `ZClean/ZClean/Features/Jobs/EditJobSheet.swift`
  - `ZClean/ZClean/Features/Jobs/ManageJobsView.swift`
  - `ZClean/ZClean/Features/Jobs/AddJobSheet.swift` (input model still referenced)
- History:
  - `ZClean/ZClean/Features/More/HistoryView.swift`
- Models:
  - `ZClean/ZClean/Models/Job.swift`
  - `ZClean/ZClean/Models/Contact.swift`
- Data/helpers:
  - `ZClean/ZClean/Support/JobStore.swift`
  - `ZClean/ZClean/Support/Currency.swift`
- Security:
  - `ZClean/ZClean/Security/NameCryptoService.swift`
- Notifications:
  - `ZClean/ZClean/Notifications/NotificationService.swift`

---

## Important product constraints

- Keep UX simple for non-technical daily use.
- Avoid feature creep and admin-heavy workflows.
- Prioritize reliability and speed over configurable complexity.
- Dashboard should show only what matters now.

---

## Specific review request for Claude

Please do a **code review focused on correctness and maintainability**, not style nitpicks.

Prioritize:

1. Data correctness / state transitions (collect, recurrence, edit, history)
2. SwiftData model and migration safety
3. Alert/sheet interaction safety and edge cases
4. Concurrency / async Task correctness on MainActor
5. Notification scheduling and cancellation consistency
6. Security approach for encrypted names and fallback behavior
7. Potential UI logic regressions from frequent iteration in `DashboardView.swift`

Please include:

- High severity bugs first
- Concrete file-level references
- Suggested fixes (prefer minimal-change fixes first)
- Any tests or safeguards that are missing

---

## Notes

- This project has evolved quickly and `DashboardView.swift` currently contains a lot of orchestration logic.
- A useful outcome would be guidance on safe refactoring boundaries (e.g., what to extract first without breaking behavior).
