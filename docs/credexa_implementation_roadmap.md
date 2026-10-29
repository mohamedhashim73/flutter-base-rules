# Credexa implementation roadmap

## Completed foundation slice

- Firebase Core, Auth, and Firestore are initialized through shared services.
- Firestore access is scoped to the authenticated user and kept out of Cubits.
- Monetary persistence uses integer minor units, not floating point values.
- Arabic RTL login and a responsive dashboard shell are in place.
- Credit cards, providers, brands, purchases, deposits, and monthly periods have Firestore models and repository/data-source boundaries.
- Purchase and deposit posting uses Firestore transactions and stores commission snapshots.
- Treasury accounts and movements, expenses, installment accounts/payments, issued checks, and settlement records are persisted through an operations repository.
- Treasury and expense balance changes, plus installment payments, use Firestore transactions.
- Auditable create events are written for the new financial operations.
- Settlement collection requests support partial amounts, a 0.1% fee snapshot, and manual confirmation before collected totals are updated.
- Expense creation is pending approval; approval is a separate transaction that deducts treasury and records an audit event.
- An Arabic responsive reporting screen summarizes credit purchases/commissions, treasury, pending collections, card debt, and settlement reconciliation.
- In-app notifications are persisted with unread/read state and generated for approval, installment, check, and collection workflows.
- Treasury approval thresholds are configurable, large employee movements remain pending until manager approval, and the Flutter scope switches to shared organizations when an `organizationId` claim is present.
- Firebase Functions provide trusted manager-only user creation, role/permission assignment, organization user listing, and threshold updates.
- Internal treasury transfers preserve total funds while moving balances transactionally; personal withdrawals are kept separate from operating expenses; reconciliation records preserve expected/actual balances and differences.
- Settlements now carry separate approval metadata, enforce creator/reviewer separation, and block collection requests until approval.
- Expense categories are dynamic, persisted, selectable, and permission-gated rather than hardcoded.
- Receiving-company and bank-account catalogs are now loaded by credit and operations features; new brands snapshot their receiving company and settlement bank route, and settlements preserve that historical destination.
- Bank accounts carry opening/current balances; confirmed collections update the routed bank account transactionally, while reconciliation writes a traceable adjustment movement with before/after balances.
- Installment accounts carry monthly obligations and installment counts, and each payment writes a separate installment payment ledger entry.
- Issued checks support manual deducted/returned/overdue/archived lifecycle states; deducted checks update the issuing bank account once inside a transaction.
- Browser push permission is best-effort through Firebase Messaging and a web service worker; in-app notifications remain the fallback when browser/VAPID support is unavailable.
- Web push can be enabled at build time with `--dart-define=CREDEXA_FCM_VAPID_KEY=...`; the app intentionally reports permission/configuration failures without disabling in-app notifications.
- Read-heavy feature data has a tenant-scoped last-known-good SharedPreferences cache fallback; Firestore remains authoritative for reads after recovery and for every write.
- Reports provide a reconciliation view and copyable CSV output for credit purchases and settlements.
- Managers can edit existing user roles and settlement/record permissions through the users screen.
- Due and overdue installment/check reminders are generated idempotently in-app on data refresh; push delivery remains best-effort.
- Collection requests reserve their amounts transactionally, record confirmation user/time, and cannot over-commit a settlement through repeated pending requests.
- Settlement reviewers can reject a submission with a mandatory reason; bank balance changes write a bank movement ledger, and installment accounts create schedule-level records.
- Credit operations write audit events, and cash treasury accounts now accept explicit opening balances with opening movements.
- POS machines are first-class catalogs linked to brands; purchases and settlements preserve POS snapshots, and settlement records can retain included transaction IDs.
- Multiple installment schedules can be added to one account, with schedule-specific payment posting and aggregate obligation updates.
- Purchase amount corrections and soft deletion reverse card/period deltas transactionally, preserve commission snapshots, and require the matching edit/delete permission with audit events.
- Installment and check reminder windows are configurable by managers and applied during due-notification refresh.
- Installment application accounts now retain application/person/limit data; payments require an explicit treasury source and atomically post both the installment payment and treasury outflow.
- Treasury movements retain related-party and transaction-date metadata; expenses retain beneficiary, notes, and expense-date metadata; issued checks accept an explicit due date, bank label, and notes.
- Normal and instant collection requests are distinct; instant requests snapshot the 0.1% fee while normal requests use no instant fee.
- Dashboard reporting includes period filters, treasury cash-flow bars, provider/brand/transaction drill-down, settlement/obligation summaries, and clickable financial cards.
- Reports drill into expense categories and person-by-person personal withdrawal histories; managers can configure both reminder windows and the treasury approval threshold from administration.
- The temporary attachment restriction remains respected; no storage dependency was added.
- Trusted callable processing now covers validated settlement creation, gross-based instant collection reservations, credit-card limit effective dates, closed-period purchase/deposit corrections, treasury movements, bank/cash transfers, expenses, personal withdrawals, and idempotent manager approvals.
- Real browser downloads are available for Excel-compatible workbook reports and PDF reports, in addition to browser printing and CSV copying.
- A scheduled backend reminder function creates idempotent in-app installment/check reminders without requiring the application to be open.

## Next implementation phases

1. Add persistent settlement evidence only if the owner later authorizes durable file storage.
2. Run Firestore emulator/integration tests after installing Java 21 and renewing Firebase credentials.
3. Complete device/browser responsive QA and configure production FCM/VAPID credentials if web push is required.

## Verification completed in the current workspace

- `flutter test`: 8 tests passed.
- `flutter build web --release`: passed.
- `npm run build` in `functions/`: passed.
- `git diff --check`: passed.
- Targeted feature analysis for dashboard, credit cards, operations, reports, and users: passed.
- Full `flutter analyze`: no errors; remaining output is informational lint/deprecation guidance, including the intentionally web-only download/attachment adapters.

## Environment and intentional limitations

- Durable settlement evidence remains intentionally deferred because permanent file storage is disabled by the product requirement.
- Firebase CLI deployment validation is pending renewed local Firebase credentials; local TypeScript compilation and Flutter verification are available.
- Firestore emulator validation is pending a Java 21+ runtime in the current environment.
- End-to-end authorization, concurrency, export-download, and responsive browser tests remain deployment-stage verification work; a successful build does not substitute for those tests.
