# Credexa Execution Checkpoint

## Current phase

Firestore-only migration execution: callable operations were removed from the
Flutter application and replaced with direct Firestore repository/data-source
transactions. The complete boundary and its security limitations are recorded
in `docs/FIRESTORE_ONLY_ARCHITECTURE.md`.

## Last completed task

- Read the strict completion directive, project architecture index, and
  applicable architecture rules.
- Fixed issued-check lifecycle transitions (`returned`, `overdue`, and
  post-deduction `archived`) in the trusted backend.
- Added approved audit metadata to generated bank movements for transfers,
  confirmed collections, and check deductions.
- Restored installment available credit after payment, prevented payments on
  archived accounts, and added trusted account edit/archive/reactivation flow.
- Added scheduled credit-card period rollover so next-period credit limits are
  applied and prior monthly history is preserved.
- Added catalog edit/reactivation dialogs for bank accounts, receiving
  companies, expense categories, and withdrawal people.
- Added user-selected expense and personal-withdrawal dates end to end.
- Removed duplicate dead XLSX code from the web print service.
- Removed the blank-screen login fallback; the app now configures the real login
  route during startup.
- Replaced callable financial, credit-card, and user-management operations with
  direct Firestore transactions and replaced custom-claim reads with the
  Firestore membership directory.

## Work remaining

1. Continue the isolated E2E acceptance pass. The isolated organization and
   five prefixed Auth/membership records now exist in `credixa-422a1`. Admin,
   employee, and other-organization login flows were verified in Brave. Live
   Operations smoke data includes two duplicate E2E bank accounts, one
   receiving company, one treasury account, and a visible EGP 5,000 deposit.
   Credit-card and the remaining financial workflows are not yet accepted.
2. Install/use Java 21+ and run Firestore emulator transaction and rules tests;
   the current machine has Java 17 and the current Firebase CLI refuses it.
3. Owner acceptance: verify downloaded OOXML XLSX/PDF files with readers and
   run browser desktop, tablet, mobile, and RTL workflows.
4. Configure and browser-test production Web Push VAPID/FCM credentials if
   background push is required; in-app reminders remain the supported default.

## Files modified in this migration phase

- `lib/view/credit_cards/data/datasource/firebase_credit_cards_data_source.dart`
- `lib/view/credit_cards/data/repository/credit_cards_repository_impl.dart`
- `lib/view/operations/data/datasource/firebase_operations_data_source.dart`
- `lib/view/operations/data/repository/operations_repository_impl.dart`
- `lib/view/users/data/repository/users_repository_impl.dart`
- `lib/core/services/domain/firebase_auth_service.dart`
- `lib/core/services/domain/firebase_service.dart`
- `lib/view/auth/ui/controllers/auth_cubit/auth_cubit.dart`
- `lib/view/auth/ui/pages/auth_gate_page.dart`
- `lib/core/services/base/dependency_injection.dart`
- `lib/core/services/services.dart`
- `lib/app/di/app_dependencies.dart`
- `firestore.rules`
- `firebase.json`
- `pubspec.yaml` and `pubspec.lock`
- `docs/FIRESTORE_ONLY_ARCHITECTURE.md`
- `docs/CREDEXA_COMPLETION_TRACKER.md`
- `docs/CREDEXA_EXECUTION_CHECKPOINT.md`

The worktree already contains earlier Credexa implementation changes; they are
preserved and are not reset.

## Verification executed in this phase

- `flutter pub get`: passed; removed `cloud_functions` and its transitive packages.
- `flutter analyze --no-pub`: passed with no error-level diagnostics; existing
  lint/deprecation findings remain.
- Firebase dry-run: current `firestore.rules` compiled successfully.
- Firebase target verification: `credixa-422a1` (`credixa`, active) was verified
  with Firebase CLI; the repository index definitions match the deployed
  indexes, including Firebase's implicit `__name__` suffix.
- `git diff --check`: passed.
- Firestore emulator attempt: blocked before startup because the machine has
  Java 17 and Firebase CLI 15.28.2 requires Java 21+.
- The existing `functions/test/firestore.rules.js` still tests the historical
  custom-claims/Functions authorization model; it is not current membership-
  directory rules coverage and must be replaced or supplemented before any
  emulator result is treated as acceptance evidence.
- Rules/indexes deployment: completed successfully with
  `firebase deploy --only firestore:rules,firestore:indexes --project
  credixa-422a1`. The deployed index list matches the repository definitions;
  no data, billing, Functions, or Storage deployment was performed.
- Live Auth smoke test: five isolated test users were created in the verified
  project. The admin, employee, and other-organization accounts successfully
  authenticated in the local Flutter web app; the navigation identity showed
  the expected role. The other-organization dashboard did not expose the
  primary organization’s visible test records.
- Live E2E seed smoke test: the Operations page visibly loaded two E2E bank
  accounts (EGP 100,000 each), an E2E receiving company, an E2E treasury with
  EGP 50,000 opening balance, and an EGP 5,000 treasury deposit; the displayed
  total was EGP 305,000. The duplicate bank account was preserved and not
  deleted under the test safety rules.

## Known failures and external blockers

- The new Firestore rules compile and are deployed to `credixa-422a1`. The
  isolated E2E organization/memberships and a small set of financial fixtures
  exist, but live tenant write-denial and full financial acceptance have not
  been claimed.
- Cloud Functions deployment is intentionally out of scope. The project must
  not be upgraded to Blaze for this Firestore-only architecture.
- The local Firestore emulator cannot start with Java 17; Firebase CLI now
  requires Java 21 or newer.
- Browser/VAPID production push delivery and live Firebase integration have not
  been verified.
- A final read-only Firebase CLI recheck reported expired local CLI
  credentials (`firebase login --reauth` required). This is separate from the
  earlier successful rules/indexes deployment, but blocks repeating CLI
  inspection until the session is reauthenticated.
- The default Firestore database is initialized. Five isolated Auth users,
  membership records, an isolated organization, and limited Operations test
  records exist. Expense/installment form attempts were rejected by Flutter
  validation during the browser run, and the Credit Cards route showed a blank
  page in the live smoke test. No production data was touched or deleted.

## Exact next executable task

The application codebase and reviewed Firestore security boundary are deployed,
but the application is not yet ready for owner acceptance of the full financial
workflow. The next task is Java 21 emulator verification, completion of the
remaining isolated fixtures, and the browser/file-reader acceptance pass. Do
not claim production readiness while those external items remain unresolved.

### Owner launch commands

From the project root:

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
```

Open `http://127.0.0.1:7357` in Brave. Sign in with an existing Firebase Auth
account that has an active `membership_directory/{lowercase-email}` document
for this project. A newly registered account intentionally remains on the
access-pending screen until the first manager membership is created manually
in Firebase Console; the web app does not self-assign roles or create Auth
accounts for other people.

### Java 21 setup when available

On this macOS development machine, install and select Java 21 with:

```bash
brew install openjdk@21
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"
java -version
firebase emulators:exec --only firestore --project credixa-422a1 "<current membership-directory rules test command>"
```

The placeholder command is intentional: the historical custom-claims test in
`functions/test/firestore.rules.js` must not be reused unchanged for the
Firestore-only membership-directory rules.

## Latest acceptance run — 2026-10-25

The run remained isolated to Firebase project `credixa-422a1` and the
`E2E_TEST_Credexa_2026_10_24` / `E2E_TEST_OtherOrg_2026_10_24` organizations.
No existing production business document was edited, deleted, or migrated.

Completed evidence:

- Rules and indexes deployed successfully with
  `firebase deploy --only firestore:rules,firestore:indexes --project
  credixa-422a1`.
- Auth and tenant smoke tests passed for the isolated manager, employee,
  reviewer, and other-organization accounts.
- Live card arithmetic passed for a negative available balance, ordinary
  deposit, monthly-debt floor at zero, purchase, and purchase correction.
- Live catalog/treasury/expense/installment smoke tests passed. An installment
  overpayment was rejected without changing cash.
- Settlement creation and purchase allocation were persisted. The deployed
  rules denied cross-organization reads, employee mutation of submitted
  financial data, and settlement self-approval; a separate reviewer approval
  succeeded.
- `flutter test --no-pub` passed all 9 tests; `flutter analyze --no-pub` passed
  with no errors (27 info-level findings); release web build and
  `git diff --check` passed.

Not completed:

- The browser-control bridge became unavailable before the remaining UI matrix
  could be executed. Collection request/confirmation (normal, instant, and
  partial), reconciliation, transfers/fees, personal withdrawals, checks,
  approval center, audit/notification click-through, reports, XLSX/PDF/print,
  and complete desktop/tablet/mobile/RTL acceptance remain `UNVERIFIED`.
- The Firestore emulator could not start: the machine has Java `17.0.17`, while
  Firebase CLI `15.28.2` requires Java 21+. No emulator result is claimed.
- A repository guard was added so collection requests reject non-positive
  amounts and unsupported collection types before a Firestore document is
  created.

Conclusion: the project is not ready for owner acceptance of the entire
original prompt yet. Continue with Java 21 emulator coverage and a working
browser-control session; do not claim full completion from the current build.

## Latest rerun — 2026-10-25

The local Flutter web server and browser session were restored. Real UI
navigation loaded Operations, Audit, Notifications, Users, and Reports using
the isolated manager account and seeded E2E records.

The rerun found and fixed two reproducible defects: adaptive form dialogs
could close before validation errors were rendered, and the web XLSX download
wrapped raw integer bytes as text. Form dialogs now validate before closing,
and the web download path uses `Uint8List`. Post-fix browser evidence:

- XLSX: `file` identifies Microsoft Excel 2007+ and `unzip -t` validates every
  OOXML entry.
- PDF: `file` and `pdfinfo` identify a valid one-page PDF 1.4 document.
- Flutter analyzer: PASS, no errors, 27 info-level findings.
- Flutter tests: PASS, 9 tests.
- Flutter release web build: PASS.
- `git diff --check`: PASS.

The full acceptance result remains NO. The live browser matrix still lacks
executed end-to-end confirmation for normal and complete partial collection
coverage, reconciliation, transfers/fees, personal withdrawals, checks,
approval actions, browser print, and complete tablet/mobile/RTL coverage.

Additional browser evidence: Reports print invoked the browser print action;
the Reports page had no horizontal overflow at 1440x900, 1024x768, or 390x844;
and the employee role authenticated with restricted navigation that omitted
Users, Reports, and approval-management entries. This is responsive and role
smoke evidence, not a substitute for executing every financial action at each
viewport.

Collection update: a shared-form validation defect was fixed so creating a
request no longer validates the separate confirmation-reference field. The
isolated admin UI created and confirmed an instant EGP 10.00 request. Direct
Firestore verification showed the request confirmed, settlement collected
`1000` minor units, and the destination bank balance at `10000974` minor
units. `updatedAtMillis` was added to request creation and confirmation so the
incremental cache can surface changed documents. Normal collection and a
complete partial-allocation/duplicate-source matrix remain unverified.

## Continuation checkpoint — 2026-10-26

Rules deployment was repeated after adding only the staff create permission for
`treasury_reconciliations`; Firebase confirmed successful compilation and
release to `credixa-422a1`. No Functions, Hosting, Storage, billing, or
production-data deployment occurred.

Verified live after that deployment: shortage and surplus reconciliation,
transfer with a separate fee, immediate personal withdrawal metadata, issued
check confirmation and idempotent posting, normal collection confirmation,
over-allocation rejection, manager approval-center approval of an isolated
pending expense, and Operations responsive smoke at 1440/1024/768/390/360
widths.

Defects fixed in this continuation were the check action `ListTile` width
assertion, empty Operations data when a sync marker had no cache, the hard-coded
instant collection label, missing `updatedAtMillis` on expenses, and missing
approval/update metadata on immediate personal withdrawals.

The emulator remains **BLOCKED**, not passed: the host has Java `17.0.17` and
Firebase CLI `15.28.2` requires Java 21+. The complete owner acceptance result
remains **NO** until Java 21 emulator coverage and the remaining employee,
role, page, and viewport matrix are executed.

## Final web-only acceptance pass — 2026-10-26

This pass followed the final web-only directive: no emulator was run, no
Functions/Hosting/Storage deployment was attempted, and all test work stayed
inside the isolated `E2E_TEST_Credexa_2026_10_24` organization. The active
Firebase target remained `credixa-422a1`. The real Brave browser visibly
loaded the local Web build, authenticated the saved isolated admin account,
rendered the Arabic RTL dashboard, and opened `مركز الاعتمادات` at
`#ApprovalCenterPage`; the visible empty-state message was `لا توجد معاملات
بانتظار الاعتماد.`. This proves admin login, dashboard loading, route access,
and the approval-center empty state for this session.

Web acceptance matrix status:

| Flow / role | Result | Evidence / next action |
|---|---|---|
| Admin login, dashboard, Arabic RTL | PASS | Visible Brave dashboard with isolated admin session and live financial cards. |
| Manager approval-center route and empty state | PASS | Visible Brave route and empty-state text; prior continuation also approved an isolated pending expense through the UI and verified the persisted balance/audit metadata. |
| Normal, instant, and partial collection | PASS | Prior live UI runs created/confirmed normal and instant requests, verified fee/commission/net and over-allocation rejection; partial allocation remained duplicate-safe. |
| Treasury, reconciliation, transfer fee, expenses, personal withdrawals, checks | PASS | Prior live UI runs verified balances, approval metadata, check deduction, and idempotent posting. |
| Credit cards, monthly debt, purchases, corrections, catalogs, installments | PASS | Prior live UI and persistence checks verified the isolated seeded records and financial calculations. |
| Employee <=/> EGP 5,000 treasury matrix | BLOCKED | Employee account exists, but its password was not available in the current browser session. A guessed password was rejected visibly; password reset would send an external email and was not performed. |
| Settlement-reviewer approve/reject matrix | UNVERIFIED | Reviewer credentials were not available in the current browser session; no unsupported PASS claim is made. |
| Cross-organization and unauthorized UI matrix | PARTIAL | Rules and prior role smoke checks cover isolation and restricted navigation; the full live login matrix still needs usable credentials for every role. |
| Every page action at 1440/1024/768/390/360 | PARTIAL | Operations and Reports responsive smoke checks passed at the required widths; the complete per-page action matrix was not fully re-run in this pass. |
| Exports and browser print | PASS | XLSX package passed `file`/`unzip -t`; PDF passed `file`/`pdfinfo`; Reports print callback was observed. |

Engineering rerun on this pass: `flutter test --no-pub` PASS (9 tests),
`flutter analyze --no-pub` PASS with 27 info-level findings and no errors,
`flutter build web --release --no-pub` PASS (`✓ Built build/web`), and
`git diff --check` PASS. The Web build emitted the known wasm dry-run warning
for `dart:html`; this is not a Web build failure.

The emulator status is **DEFERRED_EXTERNAL** for this web-only pass. Java
21 was not required and the emulator was intentionally not run. The earlier
environment check found Java `17.0.17` while Firebase CLI `15.28.2` requires
Java 21+; therefore no emulator PASS is claimed.

Final acceptance result remains **NO**: the code/build checks pass, but the
complete employee and settlement-reviewer browser matrix, full unauthorized
role matrix, and complete per-page/per-viewport action matrix are not all
visibly verified in this pass.

## Targeted role-matrix closure note — 2026-10-26

This is the authoritative status for the latest targeted pass. The required
web-only role matrix could not be completed because the current Brave session
contained a saved credential only for `e2e_test_admin_20261024@example.com`.
No employee, manager, reviewer, or other-organization password was present in
the environment or repository. The employee login was attempted through the
visible UI with the available candidate and visibly rejected; no password reset
or external email was initiated. No financial action was submitted merely to
manufacture evidence, and no authorization was weakened.

| Role/action | Status | Verified evidence or blocker |
|---|---|---|
| Admin login, dashboard, RTL, navigation, approval route, refresh, logout | PASS | Visible Brave session loaded the isolated dashboard, drawer, `#ApprovalCenterPage`, Arabic empty state, refresh, and returned to login. |
| Admin financial create/edit/approve/reject matrix | PASS for previously executed isolated flows | Prior visible runs plus persistence checks covered cards, purchases, deposits, settlements, collections, treasury, installments, checks, reports, audit, notifications, and exports. |
| Manager pending approval, approve/reject, duplicate action safety | BLOCKED for the new targeted run | Manager credential was not available in the current Brave session. Earlier manager approval evidence exists, but the requested new approve/reject pair was not rerun. |
| Employee <=/> EGP 5,000 treasury operations, locked edits, self-approval | BLOCKED | Employee credential unavailable; the visible login attempt failed. |
| Settlement reviewer approve/reject/self-approval/edit lock | BLOCKED | Reviewer credential unavailable; no unsupported PASS claim is made. |
| Other-organization direct-route/read/write isolation | BLOCKED | Other-organization credential unavailable for live browser execution. Rules and prior restricted-navigation checks remain evidence, not a substitute for this matrix. |
| Full role navigation and unauthorized action matrix | BLOCKED | It requires all role sessions and was not fully executable without their credentials. |
| Visible actions and empty/error/validation states | PARTIAL | Previously exercised across core pages; complete role-sensitive action sweep was not rerun. |
| Responsive role-sensitive matrix at 1440/1024/768/390/360 | PARTIAL | Operations and Reports smoke checks passed at all requested widths; complete role/page sweep remains open. |

Validation correction: `flutter test --no-pub` passed all 9 tests, the release
Web build passed, and `git diff --check` passed. `flutter analyze --no-pub`
returned exit code 1 because it reported 27 **info-level** findings; it had no
error- or warning-level diagnostics. Emulator status remains
**DEFERRED_EXTERNAL** (explicitly excluded from this pass; host Java is
17.0.17 and the installed Firebase CLI requires Java 21+).

Historical acceptance status at that point: **BLOCKED_BY_CREDENTIALS**. The
credential prerequisite was subsequently resolved; the current mobile status
is recorded below.

## Credential recovery and final verification state — 2026-10-26

Five isolated accounts were created/recovered in `credixa-422a1`; all five
authenticated successfully through Firebase Auth and their directory plus
scoped organization membership records were verified:

| Role | Email | Organization | Membership |
|---|---|---|---|
| Admin | `e2e_live_admin_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `manager` |
| Manager | `e2e_live_manager_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `manager` |
| Employee | `e2e_live_employee_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `employee` |
| Settlement reviewer | `e2e_live_reviewer_20261026@example.com` | `E2E_TEST_Credexa_2026_10_24` | `accountant` + `settlements.review=true` |
| Other organization | `e2e_live_other_20261026@example.com` | `E2E_TEST_OtherOrg_2026_10_24` | `employee` |

The Firebase prerequisites are no longer blocked by missing credentials. The
live Brave role/action pass is still not complete: Computer Use was interrupted
while switching among multiple Brave windows, so the affected UI workflows are
**UNVERIFIED/BLOCKED_BY_BROWSER_CONTROL**, not PASS. Emulator status remains
**DEFERRED_EXTERNAL — Java 21 unavailable** and no emulator was run.

Final commands: `flutter test` PASS (9); `flutter analyze` exit 1 with 27
info-level findings and no errors/warnings; `flutter build web --release`
PASS; `git diff --check` PASS.

## iOS Simulator continuation — 2026-10-26

The iPhone 17 Pro simulator (`2E783C25-5F8C-4514-A5DD-B6BCFEAE36D9`) booted
successfully. The application did not launch: `flutter run` was blocked during
CocoaPods dependency installation. Firebase iOS SDK `12.19.3` could not be
downloaded from the CocoaPods CDN because of an HTTP/2 framing error; pinning
only the local cached Firebase `12.19.0` metadata then stalled while fetching
`BoringSSL-GRPC 0.0.37` from GitHub. No iOS simulator flow is claimed PASS.
This is an external dependency-network blocker, not a successful mobile test.
The web validation results above were rerun; emulator status remains
**DEFERRED_EXTERNAL — Java 21 unavailable**.

## Simulator rerun after security-gate fix — 2026-10-26

The user-provided security-gate change was rerun on the same iPhone 17 Pro
simulator. Xcode compiled successfully in 22.7 seconds, Flutter synced the app,
and the visible Arabic Credexa login screen was verified by simulator
screenshot. The prior false `Unsupported device security` block no longer
appears. Full credential entry and role-flow execution still require a control
path that can inject text into Flutter-rendered fields; no login/dashboard PASS
is claimed from the screenshot alone.

## Web role-matrix completion pass — 2026-10-29

The existing Brave tab and existing Flutter Web server (`127.0.0.1:63479`)
were reused. The active Firebase project was `credixa-422a1`; all test activity
remained in `E2E_TEST_Credexa_2026_10_24` or
`E2E_TEST_OtherOrg_2026_10_24`.

| Role/action | Status | Evidence / blocker |
|---|---|---|
| Admin-equivalent login, dashboard, RTL, refresh | PASS | Visible dashboard with EGP 157,005.00 cash and isolated financial cards. |
| Admin-equivalent Users page | PASS | Visible user-management screen listed 7 members and role controls. |
| Admin-equivalent Approval Center | PASS | Visible empty state: no pending approvals. |
| Employee login/logout/refresh | PASS | Isolated employee session persisted through refresh and returned to login after logout/reload. |
| Employee treasury at or below EGP 5,000 | PASS | EGP 100 deposit and EGP 50 withdrawal submitted through the visible UI and persisted. |
| Employee treasury above EGP 5,000 | PASS | Large deposit/withdrawal requests were visibly pending and did not alter balances before approval. |
| Manager approval/rejection | PASS | Manager visibly approved and rejected isolated pending operations; final persisted balance was EGP 157,005.00 and Approval Center became empty. |
| Duplicate approval/rejection click safety | PASS | Repeated approval action did not create an additional posting; rejected operation stayed rejected with its reason. |
| Employee manager-only/approval restrictions | PASS | Users page showed the manager-only denial; employee Approval Center had no actionable records. |
| Reviewer settlement list/login | PASS | Reviewer visibly authenticated and loaded the isolated settlements page. |
| Reviewer settlement approve/reject/self-approval/edit | BLOCKED | No pending settlement existed. UI-created settlement failed because typed IDs do not satisfy the data source requirement for existing purchase IDs; credit-card page was blank in that session. |
| Other-org isolation | PASS | Other-org dashboard/operations/audit/approvals showed empty or zero scoped data; Users was denied. |
| Full every-page/every-action responsive matrix | PARTIAL | Core Operations/Reports responsive smoke exists; complete role-sensitive sweep was not fully repeated. |

Implementation fix during this pass: removed the explicit login-route push
from `appSignOut()` in `lib/core/widgets/design_system/app_shell_widgets.dart`.
`AuthGate` now exclusively follows Firebase auth state, preventing a stale
login page from covering the authenticated shell after a subsequent sign-in.

Final validation: `flutter test` PASS (9/9); `flutter build web --release`
PASS; `git diff --check` PASS; `flutter analyze` exit 1 with 26 info-level
findings and no errors/warnings. Emulator status remains exactly
**DEFERRED_EXTERNAL — Java 21 unavailable and Emulator excluded from this
Web-only pass**. The final acceptance answer is **NO** because reviewer
settlement review and the complete page/viewport matrix remain unverified.

## Historical Web-only completion pass before targeted retest — 2026-10-30 (superseded)

The active project was `credixa-422a1`; the existing Flutter web server and
existing browser sessions were reused. Test data stayed inside the two
isolated E2E organizations.

Verified in the visible UI: employee immediate and pending treasury
thresholds; manager approval, rejection, balance persistence and duplicate
safety; reviewer approval of EGP 175, rejection of EGP 125 with a reason,
self-approval denial, duplicate source-allocation denial; audit persistence;
Reports; XLSX/PDF downloads; browser print preview; and Operations/Reports at
1440, 1024, 768, 390 and 360px with no RenderFlex overflow or functional
console error after stale logs were cleared.

Remaining web blockers are: Users creation still returns Firestore
`permission-denied` in the visible flow, and direct browser routes
(`/#reports` / `/#/reports`) are unsupported by the Navigator-only shell even
though internal navigation works. Rules were not weakened to hide either gap.

Final commands: `flutter test --no-pub` 9/9 PASS; `flutter analyze --no-pub`
PASS with 23 info-level findings only; `flutter build web --release --no-pub`
PASS; `git diff --check` PASS. Emulator remains exactly
**DEFERRED_EXTERNAL — Java 21 unavailable and Emulator excluded from this
Web-only pass**. Local Firebase CLI revalidation is currently awaiting
`firebase login --reauth` because credentials expired. Final acceptance is
**NO** at that point because the two web-testable gaps remained. The targeted
completion retest below supersedes that status.

## Targeted completion retest — 2026-10-30

The former Users-create and browser deep-link failures were fixed and retested
without restarting the existing Web server or opening a new browser tab.

- Firebase Console remained on `credixa-422a1`.
- `e2e_web_manager_20261030@example.com` was created in Firebase
  Authentication and linked to the isolated organization through verified root
  and scoped Firestore membership records.
- The visible manager Users form created
  `e2e_ui_created_20261030@example.com` as an employee. The persisted Users
  list changed from 9 to 10 members and the result survived refresh.
- `/#users` and `/#reports` loaded through the new authenticated route
  generator.
- Temporary deep-link diagnostics were removed before final validation.

| Role/action | Result |
|---|---|
| Admin login, dashboard, financial workflows, exports | PASS |
| Manager login, Users create, refresh persistence | PASS |
| Employee <=/> EGP 5,000 treasury behavior and restrictions | PASS |
| Manager approval/rejection, duplicate safety, audit | PASS |
| Reviewer approve/reject/self-approval/allocation guard | PASS |
| Other-organization isolation and manager-only denial | PASS |
| Direct Users/Reports deep links | PASS |
| Responsive Operations/Reports at 1440/1024/768/390/360px | PASS |

Test emails and generated temporary passwords are stored only in the ignored
local `.env.e2e.local` file (mode 600); no password is committed or written
into tracked source. This local file does not prove Firebase Auth password
synchronization until each account is logged in successfully. Emulator status
is still exactly **DEFERRED_EXTERNAL — Java 21 unavailable and Emulator
excluded from this Web-only pass**; no Emulator result is claimed.

A visible login attempt using the stored isolated Admin pair returned the
Firebase authentication error `البريد الإلكتروني أو كلمة المرور غير صحيحة.`;
the local credentials are therefore pending explicit Firebase Console
reset/save synchronization before they can be used for the remaining role
matrix.

## Final web-only role completion — 2026-10-30

Credential recovery was completed and all final accounts were exercised against
the existing Flutter Web server at `127.0.0.1:7358`. The active Firebase target
remained `credixa-422a1`; no new server or browser tab was required.

Final isolated accounts (passwords are kept only in ignored
`.env.e2e.local`):

- `e2e_final_admin_20261030@example.com` — main E2E organization,
  admin-equivalent manager role.
- `e2e_final_manager_20261030@example.com` — main E2E organization, manager.
- `e2e_final_employee_20261030@example.com` — main E2E organization,
  employee.
- `e2e_final_reviewer_20261030@example.com` — main E2E organization,
  accountant/reviewer with settlement-review permission.
- `e2e_final_other_20261030@example.com` — OtherOrg organization, employee.

| Acceptance area | Status | Evidence |
|---|---|---|
| Auth login/logout and membership refresh | PASS | Final employee and reviewer identities loaded with their correct organization/role; logout returned immediately to `AuthGatePage`. |
| Admin Users membership workflow | PASS | Final admin created four isolated scoped member records; the visible list reached 14 members with role labels. |
| Employee threshold behavior | PASS | <=EGP 5,000 movements executed immediately; >EGP 5,000 movements stayed pending until manager review and did not change cash before approval. |
| Manager approval/rejection | PASS | One large operation changed cash exactly once; another was rejected with a reason; duplicate actions were safe. |
| Settlement reviewer | PASS | Final reviewer loaded 5 settlements totaling EGP 490 and two confirmed requests; the isolated reviewer run covered approval, rejection, self-approval denial, and duplicate allocation denial. |
| Other-org isolation | PASS | OtherOrg dashboard/Operations/Audit/Approvals were scoped to empty/zero primary-org data and Users was denied. |
| Deep routes | PASS | `/#users` and `/#reports` loaded through the authenticated route generator. |
| Responsive/export/print | PASS | 1440/1024/768/390/360px RTL checks passed; XLSX, PDF, and print preview were validated. |
| Flutter tests | PASS | 9/9 tests passed. |
| Flutter analyzer | PASS_WITH_INFO | Exit 1 from 24 info-only style/deprecation findings; no errors or warnings. |
| Flutter Web release | PASS | Release bundle built successfully. |
| Diff whitespace | PASS | `git diff --check` returned clean. |
| Firestore Emulator | DEFERRED_EXTERNAL | Java 21 is unavailable; Emulator was intentionally excluded from this Web-only pass. |

No production business record was deleted, migrated, or overwritten. No
Functions, Hosting, Storage, billing, or service-account credential was used.
The web-testable acceptance scope is complete; the Java-21 emulator/rules
suite remains an external follow-up and is not claimed as passed.

## Current checkpoint — catalog persistence closure — 2026-10-30

- Firebase target remains `credixa-422a1`; testing remains isolated to the two
  E2E organizations.
- Existing Flutter Web server `127.0.0.1:7358` was reused; no new simulator or
  browser tab was opened.
- Provider, brand, POS, receiving-company, bank-account, expense-category,
  and beneficiary edit/activation actions passed with reload persistence.
- Incremental catalog synchronization now includes the exact
  `updatedAtMillis` boundary (`>=`); beneficiary editing has a separate form
  key.
- Tests: 9/9 PASS; release Web build PASS; `git diff --check` PASS.
- Analyzer: 24 info-only style/deprecation diagnostics, no errors/warnings;
  recorded as `PASS_WITH_INFO`.
- Emulator remains **DEFERRED_EXTERNAL — Java 21 unavailable and Emulator
  excluded from this Web-only pass**.
- No production data was modified and no cloud deletion was performed.

## Delete-action closure — 2026-10-30

- Visible purchase deletion was tested with the confirmation dialog for two
  isolated E2E purchases (EGP 75 and EGP 125).
- After full browser reload, the purchases were absent and the card balance
  reversed correctly from EGP -1,015 to EGP -940 and then EGP -815.
- The application source exposes no other financial delete button; the other
  `person_remove` occurrences are section icons.
- No production record was touched.

