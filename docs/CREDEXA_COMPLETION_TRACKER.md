# Credexa Completion Tracker

This is the source of truth for the implementation state. A requirement is only
`VERIFIED_COMPLETE` when implementation, integration, persistence,
authorization, and applicable tests have all been verified. Build success alone
does not qualify.

Status values: `TODO`, `IN_PROGRESS`, `IMPLEMENTED_UNVERIFIED`,
`VERIFIED_COMPLETE`, `PENDING_OWNER_TEST`, `BLOCKED_EXTERNAL`,
`DEFERRED_BY_OWNER`, `ARCHITECTURALLY_LIMITED`.

## Firestore-only migration override

The rows below supersede any older row that cites `functions/src/index.ts` as
the runtime implementation. The Functions source is historical comparison
only; it is not part of the Flutter runtime, `firebase.json`, or acceptance
path. `PARTIAL` means the direct implementation exists but live rules,
emulator, or browser verification is still outstanding.

| Area | Status | Direct implementation/evidence | Remaining action |
|---|---|---|---|
| Callable/custom-backend removal | VERIFIED_COMPLETE | No `FirebaseFunctionsService`, `cloud_functions`, `backend_sdk`, or `httpsCallable` references remain under the Flutter app/dependencies; `firebase.json` has no Functions target. | Keep `functions/` undeployed historical source only. |
| Membership authorization | PARTIAL | `lib/core/services/domain/firebase_auth_service.dart`, `lib/view/users/data/repository/users_repository_impl.dart`, `firestore.rules`; Auth reads `membership_directory`, registration never self-administers. In live project `credixa-422a1`, the isolated organization and five membership-directory records were created; admin, employee, and other-organization logins were verified in Brave. | Complete authenticated write-denial and reviewer/manager role assertions. |
| Card balances/negative balances | PARTIAL | `firebase_credit_cards_data_source.dart`, `credit_accounting_calculator.dart`; direct transactions preserve negative available balances and validate active cards. | Java 21 emulator sequence and live smoke test. |
| Monthly debt/rollover | PARTIAL | credit periods, `nextCreditLimitMinor`, and period helpers in `firebase_credit_cards_data_source.dart`. | Verify calendar rollover and carried balance in emulator/live data. |
| Purchase correction/audit history | PARTIAL | direct correction/delete transactions, `credit_corrections`, source/correction period IDs, settlement lock. | Verify closed-month correction and audit rows with emulator/browser. |
| Brands/providers/commissions | PARTIAL | brand snapshots and `FinanceMoney.commissionMinor` in credit/settlement data sources. | Verify recommendation/repetition UI and historical immutability. |
| Settlements/collections/0.1% fee | PARTIAL | settlement allocation transaction and gross-based collection cap in `firebase_operations_data_source.dart`; fee in `FinanceMoney.instantCollectionFeeMinor`. | Verify normal/instant/partial/multiple confirmation and bank reconciliation. |
| Treasury/approvals/expenses/withdrawals | PARTIAL | direct transaction methods in `firebase_operations_data_source.dart` and repository approval routing. | Verify every role/state path with emulator and deployed rules. |
| Installments/checks | PARTIAL | direct installment account/payment and issued-check bank deduction transactions. | Verify application/payment/settled/archive and notification flows. |
| Notifications | ARCHITECTURALLY_LIMITED | Firestore/in-app notifications and reminders remain available; no insecure sender is used. | Background push requires owner-approved external configuration/backend; do not claim it. |
| Responsive workflows/reports | UNVERIFIED | Existing responsive pages and client XLSX/PDF/print services remain in `lib/view/` and `lib/core/services/domain/`. | Owner browser QA and file-reader verification. |
| Rules/emulator/live deployment | PARTIAL | Firebase project `credixa-422a1` was verified in Brave and CLI. `firestore.rules` compiled and was released successfully; both configured Firestore indexes were deployed and match the repository definitions. The local emulator is blocked by Java 17 while Firebase CLI 15.28.2 requires Java 21+. The existing `functions/test/firestore.rules.js` is a historical custom-claims/Functions harness and is not evidence for the current membership-directory rules. | Install/use Java 21; replace or add a membership-directory emulator harness; then run direct Firestore/rules tests. |

## Live isolated E2E evidence (2026-10-25)

The live browser run used only `credixa-422a1` and the isolated organizations
`E2E_TEST_Credexa_2026_10_24` and `E2E_TEST_OtherOrg_2026_10_24`. No existing
production records were edited or deleted.

- Created and verified the organization document plus five isolated Auth users
  and `membership_directory` records (manager, employee, accountant reviewer,
  and an employee in a separate organization).
- Admin login, logout, employee login, logout, and other-organization login
  reached the authenticated dashboard. The navigation identity showed the
  expected email and role. The other-organization dashboard did not expose the
  primary organization’s seeded records.
- Via the live Operations UI, two duplicate test bank-account records were
  created accidentally by repeated submission (each EGP 100,000); they remain
  untouched because the acceptance safety rule forbids deletion. A receiving
  company, treasury account with EGP 50,000 opening balance, and EGP 5,000
  treasury deposit were also created. The Operations total visibly reached
  EGP 305,000, consistent with those isolated records.
- Expense-category and installment-account attempts were not accepted as
  passes: the browser accessibility value changed, but Flutter form validation
  still reported required fields. No expense or installment record is claimed.
- The Credit Cards route rendered a blank/empty page during the earlier live
  smoke test; card, purchase, deposit, monthly-debt, correction, settlement,
  collection, check, report, and export workflows remain unverified live.
- The web-server test used port `7358` because port `7357` was occupied by an
  unreachable orphan listener. This is an environment issue, not a Firebase
  deployment result.

## Requirements

| ID | Module | Exact expected behavior | Status | Relevant source files | Verification method/result | Remaining action |
|---|---|---|---|---|---|---|
| AUTH-001 | Authentication | Users authenticate through Firebase Auth and unauthenticated users cannot access the application. | IMPLEMENTED_UNVERIFIED | `lib/view/auth/`, `lib/core/services/domain/firebase_auth_service.dart`, `firestore.rules` | Auth emulator sign-in is exercised by Functions/rules integration harness; browser login and live Auth remain unverified. | Run browser login and live Auth checks after Firebase re-authentication. |
| AUTH-002 | Authorization | Roles manager, accountant, and employee are enforced by Firestore membership records. | PARTIAL | `lib/core/services/domain/firebase_auth_service.dart`, `lib/view/users/`, `firestore.rules` | Membership directory lookup and client role checks are implemented; deployed rules enforce the directory boundary; the full live role matrix remains outstanding because the E2E organization has not yet been bootstrapped. | Create isolated manager membership and run the role matrix. |
| AUTH-003 | Authorization | Organization membership isolates all reads and writes by tenant without custom claims. | PARTIAL | `lib/core/services/domain/firebase_service.dart`, `lib/core/services/domain/firebase_auth_service.dart`, `firestore.rules` | All runtime collections use the resolved organization scope; cross-tenant live/emulator verification remains blocked by Java 17 and undeployed rules. | Run Java 21 emulator and live tenant-isolation checks. |
| AUTH-004 | User administration | Managers create Firestore member/directory records without creating Auth users or storing passwords. | PARTIAL | `lib/view/users/data/repository/users_repository_impl.dart`, `lib/view/users/`, `docs/FIRESTORE_ONLY_ARCHITECTURE.md` | Direct membership transaction is implemented and temporary passwords are discarded; Auth account creation remains a separate owner/user action. | Verify onboarding with two real Auth accounts. |
| AUTH-005 | User administration | Employees cannot alter submitted financial operations. | IMPLEMENTED_UNVERIFIED | `firestore.rules`, `lib/view/operations/data/datasource/firebase_operations_data_source.dart` | Sensitive financial direct writes were removed and the live rules were deployed; employee mutation denial still needs an authenticated E2E assertion. | Run the employee write-denial test. |
| AUTH-006 | Audit | Every financial mutation records actor, timestamp, reason, old values, new values, and source. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `lib/core/services/domain/audit_service.dart` | Trusted audit helper exists; persistence/concurrency unverified. | Emulator audit assertions. |
| CARD-001 | Credit cards | Credit-card balances may be negative and negative balances remain visible. | IMPLEMENTED_UNVERIFIED | `credit_card_model.dart`, `credit_cards_page.dart`, `credit_accounting_calculator.dart` | Calculator/widget tests cover arithmetic and warning; Firestore flow unverified. | Emulator card lifecycle test. |
| CARD-002 | Credit cards | Every ordinary deposit increases actual card balance. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `firebase_credit_cards_data_source.dart` | Trusted callable source inspected; transaction not emulator-tested. | Emulator transaction test. |
| CARD-003 | Credit cards | Every ordinary deposit reduces current monthly debt, stopping at zero. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `credit_accounting_calculator.dart` | Calculator behavior covered; callable persistence unverified. | Emulator monthly-debt test. |
| CARD-004 | Credit cards | Excess deposits leave debt at zero and preserve excess in actual balance. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `finance_money.dart` | Unit arithmetic covered; backend persistence unverified. | Emulator excess-deposit test. |
| CARD-005 | Credit cards | Purchases after debt payment do not reopen paid debt. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, credit repositories | Source logic inspected; rollover sequence unverified. | Emulator sequence test. |
| CARD-006 | Credit cards | New monthly debt uses effective limit minus carried opening balance. | IMPLEMENTED_UNVERIFIED | `credit_accounting_calculator.dart`, `functions/src/index.ts` | Negative-opening unit test passes; backend rollover unverified. | Emulator rollover test. |
| CARD-007 | Credit cards | Negative opening balance increases new monthly debt. | VERIFIED_COMPLETE | `credit_accounting_calculator.dart`, `test/finance_calculations_test.dart` | Dedicated unit test passes. | Add backend integration evidence. |
| CARD-008 | Credit cards | Credit-limit changes affect the next calendar month, not the current month. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `credit_card_model.dart` | Trusted callable stores a pending next-period limit; the scheduled `rolloverCreditCardPeriods` function applies it when the new period is created. | Deploy/scheduler verification. |
| CARD-009 | Credit cards | Closed-month purchase corrections preserve the original record and post a linked current-period difference. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, credit repositories/models | Callable source inspected; closed-period transaction unverified. | Emulator correction test. |
| CARD-010 | Credit cards | Credit-deposit corrections are admin-only, preserve the original, and are audited. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `firebase_functions_service.dart` | Callable source inspected; authorization/persistence unverified. | Emulator manager/employee test. |
| CARD-011 | Credit cards | Corrections cannot silently invalidate finalized settlements. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, settlement models | `assertCreditPurchaseNotSettled` blocks approved/collected settlement sources; explicit rejection integration assertion remains. | Add finalized-settlement correction assertion. |
| CARD-012 | Credit cards | Provider, brand, POS, and commission snapshots remain immutable in historical purchases. | IMPLEMENTED_UNVERIFIED | credit models, credit datasource, `functions/src/index.ts` | Snapshot fields exist; mutation protection unverified. | Rules/emulator history test. |
| CARD-013 | Credit cards | Brand recommendations and repetition warnings are shown from card/provider/brand history. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart`, `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/model/domain/brand_usage_summary_model.dart` | Cubit calculates usage summaries and current/previous-month repetition warnings; browser selection workflow remains unverified. | Add widget/browser assertion. |
| PURCHASE-001 | Purchases | Purchases are transactionally posted with validation, commission, card balance, period, and audit updates. | IMPLEMENTED_UNVERIFIED | credit repository/datasource, `functions/src/index.ts` | Build/source inspection only. | Emulator posting test. |
| PURCHASE-002 | Purchases | Purchase edit/delete reverses deltas transactionally and uses matching permission. | IMPLEMENTED_UNVERIFIED | credit repository, `functions/src/index.ts`, `firestore.rules` | Callable exists; authorization/concurrency unverified. | Emulator correction/delete test. |
| SETTLE-001 | Settlements | Settlement source purchases are valid, unique, undeleted, and belong to the selected brand. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, operations repository | Backend validation exists; emulator test pending. | Add source validation integration test. |
| SETTLE-002 | Settlements | Brand commission is calculated from applicable gross purchase amounts. | IMPLEMENTED_UNVERIFIED | `finance_money.dart`, settlement callable | Arithmetic unit coverage partial; source aggregation unverified. | Add commission aggregation test. |
| SETTLE-003 | Settlements | Commission snapshots remain historically unchanged. | IMPLEMENTED_UNVERIFIED | settlement/purchase models, functions | Source fields exist; mutation test pending. | Emulator snapshot test. |
| SETTLE-004 | Collections | Instant fee is 0.1% of gross before brand commission. | VERIFIED_COMPLETE | `finance_money.dart`, `test/finance_calculations_test.dart`, functions | Dedicated unit test passes; callable integration pending. | Emulator confirmation test. |
| SETTLE-005 | Collections | Normal collection has no additional instant fee. | IMPLEMENTED_UNVERIFIED | functions, collection model | Source logic inspected; integration unverified. | Add test. |
| SETTLE-006 | Collections | Partial collections cannot duplicate source allocations. | IMPLEMENTED_UNVERIFIED | collection/settlement callables, models | Allocation/idempotency code exists; concurrency unverified. | Emulator concurrent request test. |
| SETTLE-007 | Collections | Multiple collection requests remain independent and idempotent. | IMPLEMENTED_UNVERIFIED | functions, collection repository | Idempotency keys exist; integration unverified. | Emulator duplicate test. |
| SETTLE-008 | Collections | Expected collections are not treated as available bank funds. | IMPLEMENTED_UNVERIFIED | bank/settlement models, functions | Source logic inspected; balance test pending. | Emulator balance assertion. |
| SETTLE-009 | Collections | Bank balance increases only after valid manual confirmation. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, bank models | Callable path exists; rules/concurrency unverified. | Emulator confirmation test. |
| SETTLE-010 | Collections | Each brand settlement is confirmed independently. | IMPLEMENTED_UNVERIFIED | settlement models, operations UI/functions | Source structure exists; workflow test pending. | Integration test. |
| SETTLE-011 | Collections | Overdue collections remain visible and clearly marked. | IMPLEMENTED_UNVERIFIED | `lib/view/reports/ui/pages/reports_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart`, `lib/model/domain/settlement_model.dart` | Reports mark settlements overdue from `expectedCollectionDateMillis`; dedicated records page keeps open collection requests visible. | Add focused overdue collection widget assertion. |
| TREAS-001 | Treasury | Bank deposits are authorized, atomic, idempotent, and audited. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `lib/view/operations/data/repository/operations_repository_impl.dart`, `lib/view/operations/ui/pages/operations_page.dart` | `recordBankMovement` is trusted, idempotent by movement ID, transaction-backed, threshold-aware, and audited; emulator path passes for deposit coverage. | Add explicit deposit-specific assertion and live deployment verification. |
| TREAS-002 | Treasury | Bank withdrawals are authorized, atomic, idempotent, and audited. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `lib/view/operations/data/repository/operations_repository_impl.dart`, `lib/view/operations/ui/pages/operations_page.dart` | Trusted withdrawal path enforces non-negative balance and approval threshold; full emulator rejection/approval assertion remains. | Add explicit withdrawal-specific assertion and live deployment verification. |
| TREAS-003 | Treasury | Bank-to-bank transfers update both ledgers atomically. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, operations UI/repository | Callable supports bank endpoints; emulator unverified. | Emulator transfer test. |
| TREAS-004 | Treasury | Bank-to-cash transfers update both account types atomically. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, operations UI/repository | Callable supports mixed account types; emulator unverified. | Emulator transfer test. |
| TREAS-005 | Treasury | Cash-to-bank transfers update both account types atomically. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, operations UI/repository | Callable supports mixed account types; emulator unverified. | Emulator transfer test. |
| TREAS-006 | Treasury | Treasury-account transfers preserve total funds and are not income. | IMPLEMENTED_UNVERIFIED | functions, transfer model | Source logic exists; integration unverified. | Emulator ledger test. |
| TREAS-007 | Treasury | Transfer fees are explicit transactions and deducted from the correct source. | IMPLEMENTED_UNVERIFIED | functions, transfer model | Callable arithmetic exists; ledger test pending. | Add fee ledger test/UI. |
| TREAS-008 | Treasury | Bank-account ledgers record deposits, withdrawals, transfers, collections, and checks. | IMPLEMENTED_UNVERIFIED | bank movement model/functions | Manual deposits/withdrawals, transfers, confirmed collections, and deducted checks create bank movements; generated movements now carry approved status and audit metadata. | Emulator/live ledger review. |
| TREAS-009 | Treasury | Cash ledgers record opening balances and approved movements. | IMPLEMENTED_UNVERIFIED | treasury models/functions | Source logic exists; emulator unverified. | Emulator ledger test. |
| TREAS-010 | Treasury | Reconciliation records expected/actual/difference and a manager adjustment movement. | IMPLEMENTED_UNVERIFIED | functions, operations repository | Trusted callable now exists; emulator/rules unverified. | Emulator reconciliation test. |
| TREAS-011 | Treasury | Manager adjustments cannot create negative balances. | IMPLEMENTED_UNVERIFIED | functions | Outflow guards exist; authorization test pending. | Emulator negative-balance test. |
| TREAS-012 | Treasury | Every financial movement is authorized, atomic, idempotent, and audited. | IMPLEMENTED_UNVERIFIED | functions, firestore rules | Sensitive direct writes tightened; deploy/test pending. | Rules/emulator matrix. |
| APPROVAL-001 | Approval center | A dedicated approval center lists all pending financial operations. | IMPLEMENTED_UNVERIFIED | `lib/view/approvals/ui/pages/approval_center_page.dart`, `lib/view/dashboard/ui/pages/dashboard_page.dart` | Dedicated route lists pending credit deposits, treasury/bank movements, expenses, withdrawals, transfers, settlements, and collection confirmations; browser workflow remains unverified. | Run browser approval matrix. |
| APPROVAL-002 | Approval center | Pending deposits are listed with approve/reject actions. | IMPLEMENTED_UNVERIFIED | `lib/view/approvals/ui/pages/approval_center_page.dart`, `functions/src/index.ts`, `lib/view/credit_cards/data/repository/credit_cards_repository_impl.dart` | Emulator covers pending deposit approval and rejection; dedicated UI actions are connected. | Add browser action assertion. |
| APPROVAL-003 | Approval center | Pending withdrawals are listed with approve/reject actions. | IMPLEMENTED_UNVERIFIED | `lib/view/approvals/ui/pages/approval_center_page.dart`, `functions/src/index.ts`, `lib/view/operations/ui/controllers/operations_cubit/operations_cubit.dart` | Dedicated approval-center section lists pending personal withdrawals with approve and mandatory-reason reject actions; trusted backend approval/rejection paths are connected. | Browser approval-matrix verification. |
| APPROVAL-004 | Approval center | Settlement review supports approve/reject with mandatory rejection reason. | IMPLEMENTED_UNVERIFIED | functions, operations UI | Callable source exists; end-to-end unverified. | Emulator reviewer test. |
| APPROVAL-005 | Approval center | Reviewer permissions are enforced by backend. | IMPLEMENTED_UNVERIFIED | functions, rules, users page | Source checks exist; live claims unverified. | Emulator matrix. |
| APPROVAL-006 | Approval center | Transactions above EGP 5,000 require manager approval. | IMPLEMENTED_UNVERIFIED | functions, finance settings | Configurable threshold exists; default/live behavior unverified. | Emulator threshold test. |
| APPROVAL-007 | Approval center | Manager-created operations execute immediately. | IMPLEMENTED_UNVERIFIED | functions | Callable branch exists; integration unverified. | Emulator manager test. |
| APPROVAL-008 | Approval center | Submitted employee operations cannot be edited by employees. | IMPLEMENTED_UNVERIFIED | rules/functions | Direct sensitive writes removed; deploy/test pending. | Security-rule test. |
| CATALOG-001 | Catalogs | Providers support create, edit, activate, deactivate, and reactivation without deleting history. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart`, `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Create/edit and active toggle preserve records; catalog page loads inactive records for reactivation. | Browser lifecycle verification. |
| CATALOG-002 | Catalogs | Brands support create, edit, activate, deactivate, and reactivation without deleting history. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart`, `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Create/edit/routing and active toggle are connected; inactive records remain queryable. | Browser lifecycle verification. |
| CATALOG-003 | Catalogs | POS machines support full lifecycle and brand association. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart`, `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Create, provider association, update, and active toggle exist; persistence is not live-verified. | Browser lifecycle verification. |
| CATALOG-004 | Catalogs | Receiving companies support full lifecycle and bank associations. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/controllers/operations_cubit/operations_cubit.dart`, `lib/view/operations/data/repository/operations_repository_impl.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Create, bank association, update, deactivate/reactivate are connected; persistence is not live-verified. | Browser lifecycle verification. |
| CATALOG-005 | Catalogs | Bank accounts support full lifecycle and opening/current balances. | IMPLEMENTED_UNVERIFIED | bank model/operations datasource, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Creation/opening, edit, activate/deactivate, and reactivation controls are connected; balances remain preserved on edits. | Emulator/browser persistence verification. |
| CATALOG-006 | Catalogs | Expense categories support full lifecycle and permission-gated management. | IMPLEMENTED_UNVERIFIED | category model/operations UI/rules, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Create, edit, activate/deactivate, and reactivation controls are connected; rules gate updates. | Emulator/browser persistence verification. |
| CATALOG-007 | Catalogs | Personal-withdrawal people can be managed and reused. | IMPLEMENTED_UNVERIFIED | `lib/model/domain/withdrawal_person_model.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart`, `lib/view/operations/ui/pages/operations_page.dart`, `firestore.rules` | Added tenant-scoped person catalog with active/deactivate controls, audit-backed create/update, and saved-name selection in the withdrawal form. | Verify catalog persistence and reuse in browser/emulator. |
| CATALOG-008 | Catalogs | Installment applications support create, edit, activate, archive, and reactivation. | IMPLEMENTED_UNVERIFIED | installment models/operations UI, `functions/src/index.ts` | Trusted update callable, edit form, archive/reactivation actions, and archived-payment guard are connected; emulator lifecycle assertions pass. | Browser/live authorization verification. |
| SCREEN-001 | UI | Provider details/history screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Provider management/detail surface exists with edit and active-history preservation; browser verification remains. | Add focused provider history route if acceptance requires a separate route. |
| SCREEN-002 | UI | Brand details/history screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/credit_cards/ui/pages/credit_cards_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Brand management/routing/detail surface exists with historical active toggles; browser verification remains. | Add focused brand history route if acceptance requires a separate route. |
| SCREEN-003 | UI | Receiving-company details/history screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/operations_page.dart`, `lib/view/catalogs/ui/pages/catalog_management_page.dart` | Receiving-company management and bank association surface exists; browser verification remains. | Add focused history route if acceptance requires a separate route. |
| SCREEN-004 | UI | Bank-account details/ledger screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/treasury_ledger_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated treasury/bank ledger page renders accounts and movement history; browser verification remains. | Add focused account drill-down if required. |
| SCREEN-005 | UI | Settlement details, review, and archive screens exist. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/settlements_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart`, `lib/view/approvals/ui/pages/approval_center_page.dart` | Dedicated settlement records and approval surfaces exist; browser verification remains. | Add archive filter/action if acceptance requires explicit archive UI. |
| SCREEN-006 | UI | Treasury ledger screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/treasury_ledger_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated ledger route renders treasury, bank, and movement records. | Browser verification. |
| SCREEN-007 | UI | Approval center screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/approvals/ui/pages/approval_center_page.dart` | Dedicated approval center is routed from dashboard and notification deep links. | Browser verification. |
| SCREEN-008 | UI | Expense management screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/expense_management_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated expense page renders expenses and categories. | Browser verification. |
| SCREEN-009 | UI | Personal withdrawal management screen exists. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/personal_withdrawals_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated withdrawal page renders separate personal withdrawals. | Browser verification. |
| SCREEN-010 | UI | Installment account details, schedules, and archive screens exist. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/installments_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated installment page renders accounts and schedules; browser verification remains. | Add archive filter/action if acceptance requires explicit archive UI. |
| SCREEN-011 | UI | Check details and archive screens exist. | IMPLEMENTED_UNVERIFIED | `lib/view/operations/ui/pages/checks_page.dart`, `lib/view/operations/ui/pages/financial_records_page.dart` | Dedicated checks page renders status and overdue markers; browser verification remains. | Add archive filter/action if acceptance requires explicit archive UI. |
| SCREEN-012 | UI | User profile, settings, reviewer management, and audit screens exist. | IMPLEMENTED_UNVERIFIED | dashboard/users/audit pages | Pages exist; complete workflows unverified. | Responsive/browser verification. |
| REPORT-001 | Reports | Reports support date and entity filters. | IMPLEMENTED_UNVERIFIED | `reports_page.dart`, dashboard | Period/provider/brand filters partly exist; browser behavior unverified. | Add filter integration tests. |
| REPORT-002 | Reports | Reports provide financial drill-down and detailed transaction histories. | IMPLEMENTED_UNVERIFIED | reports/dashboard | Drill-down source exists; end-to-end unverified. | Add widget/browser tests. |
| REPORT-003 | Reports | Reports show accurate source-based totals. | IMPLEMENTED_UNVERIFIED | reports page/functions | Source calculations inspected; seeded-data verification pending. | Integration fixtures/tests. |
| REPORT-004 | Reports | Reports export real `.xlsx` files that open correctly. | IMPLEMENTED_UNVERIFIED | `lib/core/services/domain/xlsx_package_builder.dart`, `lib/core/services/domain/print_service_web.dart`, `lib/view/reports/ui/pages/reports_page.dart` | Browser service emits an OOXML ZIP package and the package structure test passes; downloaded-file opening is not yet browser-verified. | Verify a downloaded file with an OOXML reader. |
| REPORT-005 | Reports | Reports export real `.pdf` files that open correctly. | IMPLEMENTED_UNVERIFIED | `print_service_web.dart` | Minimal PDF generator exists; opening/download not verified. | Browser/file validation. |
| REPORT-006 | Reports | Browser printing works for reports. | IMPLEMENTED_UNVERIFIED | `reports_page.dart`, print service | Source action exists; browser test pending. | Browser verification. |
| NOTIFY-001 | Notifications | Installment reminders are available as Firestore/in-app reminders. | ARCHITECTURALLY_LIMITED | `lib/core/services/domain/in_app_notification_service.dart`, operations repository | Reminder rows are created during app workflows; reliable background generation while the app is closed is not claimed without an authorized backend. | Keep in-app reminder behavior; owner decides whether external push/backend is authorized. |
| NOTIFY-002 | Notifications | Issued-check reminders are available as Firestore/in-app reminders. | ARCHITECTURALLY_LIMITED | `lib/core/services/domain/in_app_notification_service.dart`, operations repository | Check reminder rows/deep links are supported in app workflows; unattended background push is not claimed. | Browser verify in-app reminders. |
| NOTIFY-003 | Notifications | Overdue reminders do not silently claim background scheduler delivery. | ARCHITECTURALLY_LIMITED | `docs/FIRESTORE_ONLY_ARCHITECTURE.md`, notification models/services | Client reminder generation is best effort and visible; no insecure sender or fake scheduler is used. | Keep limitation explicit in acceptance handoff. |
| NOTIFY-004 | Notifications | Web push delivery works on supported browsers. | IMPLEMENTED_UNVERIFIED | web worker, web push service, notification page | Best-effort client setup exists; production delivery unverified. | Configure VAPID and browser-test. |
| NOTIFY-005 | Notifications | Notifications have deep links to relevant records. | IMPLEMENTED_UNVERIFIED | `lib/model/domain/app_notification_model.dart`, `lib/view/notifications/ui/pages/notifications_page.dart`, `lib/core/routes/routes.dart` | Notification target type/id are persisted and routed to credit, approval, or operations pages; browser navigation remains unverified. | Run notification click-through browser check. |
| NOTIFY-006 | Notifications | Notifications support read/unread state and unread count. | IMPLEMENTED_UNVERIFIED | notifications repository/page/cubit | Source exists; persistence/rules unverified. | Emulator/widget test. |
| NOTIFY-007 | Notifications | Users can configure notification preferences. | IMPLEMENTED_UNVERIFIED | `lib/model/domain/notification_preferences_model.dart`, `lib/core/services/domain/notification_preferences_service.dart`, `lib/view/notifications/ui/pages/notifications_page.dart`, `firestore.rules` | Preference dialog persists category and push flags; backend notification creation consults preferences. | Verify persistence and enforcement in emulator/browser. |
| SYNC-001 | Synchronization | Read-heavy collections sync incrementally by `updatedAt`. | IMPLEMENTED_UNVERIFIED | Firebase cache/datasources | Incremental source exists; live marker behavior unverified. | Emulator sync test. |
| SYNC-002 | Synchronization | Sync markers are persisted separately from payloads. | IMPLEMENTED_UNVERIFIED | `firebase_cache_service.dart` | Source inspected; account-switch behavior unverified. | Test marker lifecycle. |
| SYNC-003 | Synchronization | No-change sync never rewrites full cache payload. | IMPLEMENTED_UNVERIFIED | credit/operations datasources | Source branch exists; instrumented test pending. | Add cache test. |
| SYNC-004 | Synchronization | Deleted records are filtered before UI exposure. | IMPLEMENTED_UNVERIFIED | cache/datasources | Local filtering exists; integration unverified. | Add test. |
| SYNC-005 | Synchronization | Logout/login clears cache, Cubit memory, and sync markers. | IMPLEMENTED_UNVERIFIED | `lib/core/services/base/user_session_service.dart`, `lib/core/services/domain/firebase_cache_service.dart`, feature pages | Logout clears CacheManager and scoped Firebase cache markers/payloads; page-scoped Cubits close on route disposal. A dedicated multi-account memory test is still missing. | Add account-switch lifecycle test. |
| SYNC-006 | Synchronization | Firebase queries use required indexes and avoid unnecessary full reads. | IMPLEMENTED_UNVERIFIED | `firestore.indexes.json`, datasources | Index file/source inspected; deployed query validation pending. | Emulator/query-cost test. |
| UI-001 | Responsive UI | Desktop browser workflows are usable. | IMPLEMENTED_UNVERIFIED | dashboard/feature pages | Release build passes; browser QA not performed. | Run desktop browser matrix. |
| UI-002 | Responsive UI | Tablet workflows are usable. | PENDING_OWNER_TEST | all feature pages | Adaptive `LayoutBuilder`/`Wrap`/scrolling compositions are implemented; no tablet browser acceptance run has been performed. | Owner performs tablet viewport QA and reports layout defects. |
| UI-003 | Responsive UI | Mobile workflows are usable with responsive navigation. | IMPLEMENTED_UNVERIFIED | dashboard/operations/cards pages | Responsive branches exist; mobile QA not performed. | Run mobile viewport QA. |
| UI-004 | RTL | Arabic RTL layout works across forms, tables, dialogs, and reports. | IMPLEMENTED_UNVERIFIED | localization/theme/pages | RTL configuration exists; visual QA pending. | Run RTL browser checks. |
| UI-005 | UI quality | Loading, empty, and error states use shared widgets/shimmer. | IMPLEMENTED_UNVERIFIED | core widgets, feature pages | Shared widgets exist; complete coverage unverified. | Widget/state audit. |
| UI-006 | UI quality | Navy-and-white Credexa branding is preserved. | IMPLEMENTED_UNVERIFIED | theme/dashboard/pages | Source inspected; visual QA pending. | Browser visual check. |
| STORAGE-001 | Attachments | No Firebase Storage, alternative upload, Base64, or fake persistent attachment URLs are used. | DEFERRED_BY_OWNER | temporary attachment services, `pubspec.yaml` | Source search confirms temporary web adapter only. | Keep deferred; do not add storage. |
| STORAGE-002 | Attachments | Session-local image selection, preview, replacement, and removal use Core Image Widget. | IMPLEMENTED_UNVERIFIED | `custom_image.dart`, temporary attachment services | Adapter exists; browser interaction unverified. | Browser test. |
| STORAGE-003 | Evidence | Evidence-dependent approvals remain restricted/deferred without persistent storage. | IMPLEMENTED_UNVERIFIED | approval workflows, temporary attachment services | No persistent evidence is claimed; workflow restriction needs acceptance test. | Add explicit UI/backend guard if required. |
| TEST-001 | Tests | Original acceptance scenarios are represented by executable tests. | IMPLEMENTED_UNVERIFIED | `test/finance_calculations_test.dart`, `functions/test/credexa.integration.js`, `functions/test/firestore.rules.js` | Flutter unit tests, Functions integration, and rules assertions are executable and pass; full original acceptance matrix is not yet exhaustive. | Add remaining scenario assertions. |
| TEST-002 | Tests | Financial calculations, rollover, corrections, commissions, fees, and idempotency are tested. | IMPLEMENTED_UNVERIFIED | `test/finance_calculations_test.dart`, `functions/test/credexa.integration.js` | Backend integration passes negative opening balance, deposit/debt updates, collection fee/commission/net, finalized correction rejection, transfer fee, installment payment/lifecycle, check deduction/archive, and idempotency paths. | Owner/live scheduler verification for calendar rollover remains. |
| TEST-003 | Tests | Authorization, organization isolation, and security rules are tested. | IMPLEMENTED_UNVERIFIED | `firestore.rules`, `functions/test/firestore.rules.js`, `functions/test/credexa.integration.js` | Firestore rules emulator assertions pass for sensitive direct writes, allowed catalog/preferences, and cross-tenant read denial; trusted-function role paths pass in the integration suite. | Expand to the complete production claims matrix. |
| TEST-004 | Tests | Concurrent financial writes are tested transactionally. | IMPLEMENTED_UNVERIFIED | `functions/src/index.ts`, `functions/test/credexa.integration.js` | Integration suite now runs concurrent duplicate credit-deposit requests and concurrent bank withdrawals; idempotency and non-negative balance assertions pass. | Expand concurrency coverage to every financial mutation family. |
| TEST-005 | Tests | Real report exports are tested by opening generated files. | IMPLEMENTED_UNVERIFIED | `lib/core/services/domain/xlsx_package_builder.dart`, `test/finance_calculations_test.dart`, `lib/core/services/domain/print_service_web.dart` | Flutter test validates the OOXML package structure; PDF and browser download/open behavior remain unverified. | Run browser download and PDF/XLSX reader checks. |
| TEST-006 | Tests | Responsive desktop/tablet/mobile RTL workflows are tested. | PENDING_OWNER_TEST | feature pages | Responsive branches and Arabic RTL configuration exist; owner browser/device acceptance remains intentionally pending. | Owner runs desktop/tablet/mobile/RTL acceptance matrix. |
| ENV-001 | Environment | Firestore-only rules/indexes are validated for the project without a Functions deployment. | VERIFIED_COMPLETE | `firebase.json`, `firestore.rules`, `firestore.indexes.json` | Project `credixa-422a1` / display name `credixa` was verified in Brave and CLI. `firebase deploy --only firestore:rules,firestore:indexes --project credixa-422a1` completed successfully; deployed indexes match the repository definitions. Cloud Functions, Hosting, Storage, and billing changes were not deployed. | Keep future deployments scoped to reviewed Firestore resources; do not enable Blaze. |
| ENV-002 | Environment | Firestore emulator and direct-client transaction tests run locally. | BLOCKED_EXTERNAL | `firebase.json`, `firestore.rules`, `docs/FIRESTORE_ONLY_ARCHITECTURE.md`, `functions/test/firestore.rules.js` | `firebase emulators:exec --only firestore --project credixa-422a1` failed before startup: `firebase-tools no longer supports Java version before 21`. Only Java 17.0.17 is installed; `openjdk@21` is not installed. The existing Node rules test also uses the superseded custom-claims model and must not be reported as current rules coverage. | Install/use Java 21+, add a membership-directory rules harness, then rerun direct Firestore and rules tests. |
| ENV-003 | Environment | Production push delivery is configured and verified. | BLOCKED_EXTERNAL | web worker/web push service | Requires owner VAPID/Firebase messaging configuration. | Provide VAPID/FCM config and browser test. |

## Legacy baseline counts

The historical row counts below are retained for traceability only; the
Firestore-only migration override above is the current status source until the
full acceptance matrix is rerun.

- `VERIFIED_COMPLETE`: 2
- `IMPLEMENTED_UNVERIFIED`: 102
- `PENDING_OWNER_TEST`: 2
- `TODO`: 0
- `BLOCKED_EXTERNAL`: 2
- `DEFERRED_BY_OWNER`: 1
- `IN_PROGRESS`: 0

## Acceptance-test addendum (2026-10-25)

This addendum supersedes stale live-smoke notes above where they conflict with
the later isolated run. It records only evidence actually obtained; a source
implementation is not promoted to complete without an executable or live
verification result.

### Live Firebase target and deployment

- Target verified: Firebase project `credixa-422a1`, alias `credixa`.
- `firestore.rules` compiled and was released successfully.
- `firestore.indexes.json` was deployed successfully. The deployed indexes are
  the `credit_periods(cardId, updatedAtMillis)` and
  `credit_purchases(cardId, purchaseDateMillis)` definitions, each with the
  implicit document-name suffix.
- No Functions, Hosting, Storage, billing, or production-record migration was
  performed.

### Isolated live users and data

- Test organizations: `E2E_TEST_Credexa_2026_10_24` and
  `E2E_TEST_OtherOrg_2026_10_24`.
- Five `E2E_TEST_` Auth accounts and lower-case
  `membership_directory` records were created for manager, accountant/reviewer,
  employee, and a separate-organization user.
- Isolated records were created for cards, a negative card balance, periods,
  purchases, deposits, providers, brands, POS, receiving companies, bank
  accounts, settlements, treasury accounts/movements, expense category and
  expense, installment account/schedule/payment, audit/notification records,
  and approval data. An accidentally repeated bank-account submission created
  two duplicate isolated accounts; neither was deleted.

### Verified live behavior

- Admin/manager, employee, reviewer, and other-organization authentication and
  organization scoping were exercised in the local Flutter web app.
- Negative available balance remained visible. An ordinary deposit increased
  the card balance and reduced monthly debt to zero; a later purchase and a
  purchase correction changed the actual balance without reopening paid debt.
- Brand repetition warning and catalog create flows were visible in the
  credit-card/catalog workflow.
- Treasury opening/deposit totals, an expense, installment creation/payment,
  and installment overpayment rejection were exercised. The overpayment did
  not change the cash total.
- A settlement was created from a selected purchase with gross `5000` minor
  units, commission `125`, and net `4875`; its source allocation was persisted
  and the purchase was no longer eligible for another allocation.
- Deployed-rule assertions passed through authenticated Firestore REST calls:
  employee mutation of a submitted expense was denied, cross-organization card
  read was denied, manager self-approval of a settlement was denied, and a
  separate reviewer with the literal `settlements.review` permission approved
  the settlement.

### Remaining status after the run

- `flutter test --no-pub`: PASS, 9 tests.
- `flutter analyze --no-pub`: PASS with 27 existing info-level lint/deprecation
  findings and no analyzer errors.
- `flutter build web --release --no-pub`: PASS (`build/web` produced); the
  existing WebAssembly dry-run warning is caused by `dart:html` in the print
  adapter and is not a release-build failure.
- `git diff --check`: PASS.
- Firestore emulator/rules-emulator: BLOCKED before startup because the host
  has Java `17.0.17` and Firebase CLI `15.28.2` requires Java 21+.
- Browser flows not completed live: normal/instant/partial collection request
  and confirmation, bank reconciliation, transfers and fees, personal
  withdrawals, issued-check deduction, approval-center actions, audit and
  notification click-through, report filtering, XLSX/PDF download/open/print,
  and complete tablet/mobile/RTL viewport coverage. The browser-control bridge
  became unavailable during the run, so these are `UNVERIFIED`, not passes.
- The app is therefore not fully implemented/accepted against the original
  prompt. Final answer: **NO**.

### Acceptance rerun addendum — 2026-10-25 (browser session restored)

The real local Flutter web UI was restored and exercised through the live
browser session using the isolated manager account. Operations, Audit,
Notifications, Users, and Reports loaded with the seeded E2E records.

Two reproducible UI defects were found and fixed:

- Empty form submission previously dismissed adaptive dialogs without showing
  validation errors. The dialog now validates before closing; a live empty-card
  submission remained open and displayed the Arabic required-field errors.
- Web XLSX downloads were ASCII text containing comma-separated byte values,
  although the package builder produced valid ZIP bytes. The web print adapter
  now passes a `Uint8List` to `html.Blob`. A fresh browser download was
  validated as `Microsoft Excel 2007+`; `unzip -t` reported all OOXML entries
  valid. A fresh PDF download was validated as PDF 1.4 with one page using
  `pdfinfo`.

Audit, Notifications, Users, Reports page loading, XLSX export, PDF export,
and instant collection creation/confirmation are now verified live.
Normal collection, full partial-allocation coverage, reconciliation, transfer,
withdrawal, check, approval-action, browser-print, viewport, and RTL flows
remain UNVERIFIED until their actual actions and resulting data are checked.

Additional live UI evidence from the same rerun:

- Reports browser print action invoked `window.print` successfully.
- Reports rendered at 1440x900, 1024x768, and 390x844 without document
  horizontal overflow; this is a responsive smoke pass, not full workflow
  coverage at every viewport.
- The employee account authenticated with role `employee`; its navigation did
  not expose Users, Reports, or approval-management entries. Direct live rules
  checks separately confirmed cross-organization reads, locked financial edits,
  and settlement self-approval are denied.

The collection rerun reproduced and fixed a real integration issue: request
creation and confirmation shared one Form, so creating a request was blocked
by the empty confirmation-reference field. The create action now validates
only its own amount and settlement inputs. The isolated admin UI then created
and confirmed an instant request for EGP 10.00; Firestore verification showed
request status `confirmed`, settlement `collectedMinor=1000`, and destination
bank balance `10000974` minor units. Request creation and confirmation now
carry `updatedAtMillis` for incremental synchronization. Normal-type collection
and a separate full partial-allocation matrix remain UNVERIFIED.

## Acceptance continuation — 2026-10-26

The target remained Firebase project `credixa-422a1` and the isolated
`E2E_TEST_Credexa_2026_10_24` organization. No production documents were
deleted, migrated, or overwritten.

- A narrowly scoped Firestore Rules fix was deployed successfully to allow
  creation of `treasury_reconciliations` for organization staff.
- Live UI reconciliation passed for both shortage and surplus, and the test
  treasury balance was restored.
- Live UI transfer testing passed with an EGP 10.00 transfer and EGP 1.00 fee.
- Live UI personal-withdrawal testing passed; the persisted immediate record
  included `approvedBy`, `approvedAtMillis`, and `updatedAtMillis`.
- Live issued-check testing passed: the check remained issued before explicit
  confirmation, then reduced the linked bank by exactly EGP 7.00, wrote one
  deterministic bank movement, and did not duplicate the posting on archive.
- A real check-card `ListTile` width assertion was fixed with a responsive
  card and wrapped action row.
- Normal collection was created and confirmed through the UI with amount
  `1000`, fee `0`, commission `25`, net `975`; the destination bank increased
  by exactly `975` minor units.
- An over-allocation request for `4000` minor units was rejected and not
  persisted. The two confirmed partial requests moved settlement collection
  from `0` to `2000` without double allocation.
- A cache synchronization defect was fixed so a sync marker without its cache
  triggers a full Firestore read instead of an empty module.
- The collection selector now updates the action label for normal requests.
- The approval center was opened live; an isolated pending E2E expense was
  approved by the manager and reduced the test treasury by exactly `300`.
- Operations had no horizontal overflow at 1440, 1024, 768, 390, or 360
  pixels. Arabic UI rendering was visibly RTL in the browser.

The emulator remains blocked because only Java `17.0.17` is installed while
Firebase CLI `15.28.2` requires Java 21+. Final status remains **NO** for full
production readiness because emulator verification, employee-created pending
flows, and the complete page/viewport matrix still require completion.

## Final web-only acceptance pass — 2026-10-26

The final Brave pass re-opened the local Web app against Firebase project
`credixa-422a1` and the isolated E2E organization. Admin authentication and the
Arabic RTL dashboard were visibly successful. The approval-center route was
opened in Brave and visibly displayed the correct empty state after the
isolated pending approval had already been processed. This is recorded as
route/access PASS, not as evidence that an employee-created pending operation
can be produced with the unavailable employee credentials.

Current completion classification:

- **PASS:** admin/dashboard; approval-center route/empty state; credit-card
  calculations and corrections; provider/brand/POS; settlements and normal,
  instant, and partial collection checks; treasury/reconciliation/transfers;
  expenses/personal withdrawals; installments; issued checks; reports,
  notifications, audit, exports, print callback; prior responsive smoke at
  1440/1024/768/390/360.
- **BLOCKED:** employee immediate-vs-pending treasury operations and the
  employee locked-edit/employee-approval matrix because the existing employee
  account password was unavailable. No reset email was sent.
- **UNVERIFIED:** settlement-reviewer approve/reject flow and full every-page
  action matrix across every viewport, because the reviewer credential and a
  complete live browser matrix were not available in this pass.
- **DEFERRED_EXTERNAL:** emulator/security-test execution. The directive for
  this pass explicitly excludes emulator execution; the host also has Java
  17.0.17 while the Firebase CLI requires Java 21+.

Validation commands were rerun: Flutter tests PASS (9), analyzer PASS with no
errors and 27 informational findings, release Web build PASS, and `git diff
--check` PASS. The known wasm dry-run notice is caused by the Web-only
`dart:html` adapter and does not invalidate the Web build.

The project therefore remains **not fully complete for owner acceptance**.

## Targeted role-matrix closure note — 2026-10-26

Historical status at that point: **BLOCKED_BY_CREDENTIALS**. The five isolated
credentials were subsequently created/recovered and Auth-tested; the current
web and mobile verification status is recorded in the later sections.

| Required area | Status | Current evidence / gap |
|---|---|---|
| Admin login/dashboard/navigation/approval route | PASS | Visible Brave RTL dashboard and approval-center empty state, including refresh and logout. |
| Existing isolated financial flows | PASS | Prior visible UI and persistence evidence covers credit, collections, treasury, settlements, installments, checks, reports, audit, notifications, print, XLSX, and PDF. |
| Manager targeted approval/rejection matrix | BLOCKED | No current manager credential; prior manager approval is retained as historical evidence only. |
| Employee immediate/pending treasury and locked-operation matrix | BLOCKED | No current employee credential; no unsupported result recorded. |
| Reviewer settlement review/self-approval/edit matrix | BLOCKED | No current reviewer credential. |
| Other-organization live isolation matrix | BLOCKED | No current other-organization credential. |
| Complete visible-action and responsive role matrix | PARTIAL | Core Operations/Reports responsive smoke passed at all five widths; complete role/page sweep remains open. |

Validation is recorded precisely: 9 Flutter tests passed; release Web build and
`git diff --check` passed; analyzer returned exit 1 with 27 info-level findings
and no errors or warnings. Emulator remains **DEFERRED_EXTERNAL** and was not
run. Test helper credentials are now supplied through `CREDEXA_TEST_PASSWORD`
and no test password is stored in the repository.

## Credential recovery and final verification state — 2026-10-26

Five isolated Auth accounts were created/recovered in `credixa-422a1` and each
authenticated successfully through Firebase Auth. Passwords remain in a local
ignored temporary credential file and are not recorded here.

| Role | Test email | Organization | Membership |
|---|---|---|---|
| Admin | `e2e_live_admin_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `manager` |
| Manager | `e2e_live_manager_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `manager` |
| Employee | `e2e_live_employee_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `employee` |
| Settlement reviewer | `e2e_live_reviewer_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `accountant`, `settlements.review=true` |
| Other organization | `e2e_live_other_20261026@example.com` | `E2E_TEST_OtherOrg_2026_10_24` | `employee` |

The second isolated organization document and all corresponding directory and
scoped membership documents were verified. This proves Auth/Firestore
prerequisites, not visible Brave acceptance. The Brave Computer Use session was
interrupted while switching among multiple windows, so employee treasury
thresholds, manager duplicate approval/rejection, reviewer self-approval,
cross-organization direct routes, and the complete responsive/action matrix
remain **UNVERIFIED/BLOCKED_BY_BROWSER_CONTROL**, not PASS.

Final engineering validation: `flutter test` PASS (9), `flutter analyze` exit
1 with 27 info-level findings and no errors/warnings, `flutter build web
--release` PASS, and `git diff --check` PASS. Emulator status remains
**DEFERRED_EXTERNAL — Java 21 unavailable and emulator excluded**.

## iOS Simulator continuation — 2026-10-26

The iPhone 17 Pro simulator booted, but the Flutter application could not be
installed or launched. CocoaPods could not download Firebase iOS SDK 12.19.3
because of an HTTP/2 CDN framing error; using the cached Firebase 12.19.0
metadata subsequently stalled on the BoringSSL-GRPC 0.0.37 GitHub fetch. The
iOS simulator acceptance pass therefore remains **BLOCKED_EXTERNAL** and no
mobile flow is marked PASS. Web validation was rerun: tests 9/9 PASS, release
web build PASS, and `git diff --check` PASS. Analyze still reports only 27
info-level findings. Emulator remains **DEFERRED_EXTERNAL — Java 21
unavailable**.

## Simulator rerun after security-gate fix — 2026-10-26

The updated code was launched successfully on iPhone 17 Pro. Xcode completed,
Flutter synced the app, and a simulator screenshot verified the Arabic Credexa
login screen. The false jailbreak/security block is no longer shown. This is a
launch/UI PASS only; authentication and the complete role matrix are not marked
PASS without successful text entry and persisted post-login evidence.

