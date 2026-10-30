# Credexa Firestore-only architecture

This document is authoritative for the migration that removes the application’s
Cloud Functions dependency. The Flutter web client now calls Firestore through
repositories and data sources only. `functions/` is retained as historical
source for comparison and is not referenced by the Flutter app or
`firebase.json`; it must not be deployed or required for acceptance testing.

## Runtime boundaries

- Firebase Authentication provides identity only.
- Firestore provides tenant-scoped data, transactions, approvals, audit rows,
  notifications, reports, and catalog data.
- `FirebaseService` is the only Firestore access boundary used by repositories
  and data sources.
- All financial mutations use Firestore transactions where multiple ledgers or
  documents must change together.
- No `cloud_functions` package, callable invocation, Cloud Run endpoint,
  custom `backend_sdk`/REST client, Firebase Storage, Base64 attachment, or web
  secret is part of the app.

## Membership and bootstrap

Authorization is stored in the Firestore `membership_directory` collection,
keyed by the normalized Firebase Auth email. A membership document contains
`email`, `organizationId`, `role`, `permissions`, `active`, `displayName`,
`createdAtMillis`, and `updatedAtMillis`.

The first manager must be created manually by the project owner in the
Firebase Console. Registration creates an Auth account only and never creates
an organization, manager role, custom claim, or privileged membership. A
manager can create organization member records and the corresponding directory
entry, but cannot create another person’s Firebase Auth account from the web
client. The supplied temporary password field is deliberately never persisted.

The app shows an access-pending screen when an authenticated account has no
active membership. This prevents an unassigned account from using a personal
fallback scope as an organization administrator.

## Direct transaction coverage

The direct Firestore data sources cover credit cards, deposits, purchases,
period rollover fields, corrections, settlement allocations, collection
requests, bank and treasury movements, transfers, reconciliations, expenses,
withdrawals, installments, checks, catalogs, notifications, and audit rows.
Credit purchase/deposit corrections keep source and correction-period IDs;
approved or collected settlements block purchase correction. Instant collection
fees are calculated as 0.1% of requested gross before brand commission, while
the bank receives the resulting net amount after manual confirmation.

## Security limitation that must remain visible

Firestore rules authorize by membership, organization, role, permission, and
basic approval state. They allow the transaction shapes required by this
client-only deployment. Firestore client rules cannot prove every invariant
between an arbitrary set of documents against a malicious browser client.
Therefore financial reconciliation, audit review, approval separation, and
manual owner acceptance are mandatory controls. This migration must not be
described as server-authoritative accounting.

## Notifications, evidence, and exports

Notifications are Firestore/in-app reminders with read state and deep-link
targets. Reliable scheduled background push is not claimed without an
authorized backend or owner-supplied push configuration. Evidence attachments
remain session-local previews only; no persistent file storage is implied.
XLSX/PDF generation remains client-side and must be verified by opening the
downloaded files, not only by a successful build.

## Verification state

- `flutter analyze --no-pub`: migration has no error-level diagnostics.
- `flutter pub get`: removed `cloud_functions` and its transitive packages.
- Firebase dry-run: the current `firestore.rules` compiles successfully.
- The intended Firebase target is `credixa-422a1` (`credixa`, active). Rules and
  indexes compile in dry-run mode, and the repository index definitions match
  the currently deployed indexes. `firebase deploy --only
  firestore:rules,firestore:indexes --project credixa-422a1` completed
  successfully; no Functions, Hosting, Storage, billing, or business-data
  deployment was performed.
- Local Firestore emulator verification is currently blocked before startup by
  the installed Java 17 runtime; Firebase CLI 15.28.2 requires Java 21+.
- The existing `functions/test/firestore.rules.js` is historical test code for
  custom claims and Functions-era authorization. It is not current evidence for
  `membership_directory` authorization and must be replaced or supplemented
  before emulator results are used for acceptance.
- Five isolated E2E Auth users, the isolated organizations, and corresponding
  `membership_directory` records were created in `credixa-422a1`. Admin,
  employee, and other-organization logins were verified in the local Flutter
  web app. Limited Operations fixtures were created through the UI (two E2E
  bank accounts, one receiving company, one treasury account, and a visible
  EGP 5,000 treasury deposit). The full financial, desktop/tablet/mobile/RTL,
  and export acceptance remains unverified. Expense/installment attempts were
  rejected by Flutter form validation and the Credit Cards route showed a
  blank/empty live page during smoke testing.

## Latest live acceptance addendum — 2026-10-25

Later isolated testing supersedes the stale smoke-test wording above for the
flows listed here. The verified target remained `credixa-422a1`; all records
used the `E2E_TEST_` namespace or a dedicated test organization.

- Rules and indexes were successfully deployed, with no Functions, Hosting,
  Storage, billing, or production-data operation.
- Live card testing verified a negative balance, ordinary deposit, monthly-debt
  floor, purchase, repetition warning, and purchase correction.
- Live Operations testing verified catalog setup, treasury opening/deposit,
  expense, installment payment, and rejection of an installment overpayment.
- A settlement with purchase allocation was persisted. Its gross/commission/net
  values were `5000`/`125`/`4875` minor units.
- Authenticated rule checks denied cross-organization reads, employee edits of
  submitted financial data, and settlement self-approval. A separate reviewer
  with `settlements.review` successfully approved the test settlement.
- Flutter tests, analyzer, release web build, and whitespace validation passed.

The full acceptance matrix is still not complete: the browser-control bridge
became unavailable before collection confirmation, reconciliation, transfers,
withdrawals, checks, approval-center, audit/notification click-through,
reports/exports/print, and all viewport/RTL flows could be exercised. The
Firestore emulator remains blocked by Java `17.0.17`; Firebase CLI `15.28.2`
requires Java 21+. These items remain unverified and must not be represented as
production-ready evidence. The collection repository now also rejects
non-positive amounts and unsupported collection types before writing.

## Export and live UI verification update — 2026-10-25

The restored live browser session loaded Operations, Audit, Notifications,
Users, and Reports against the isolated test organization. Empty adaptive form
submission exposed a dialog-validation defect; the shared dialog now validates
before dismissing, and the browser retest confirmed the required-field errors
remain visible.

The web XLSX adapter also had a binary delivery defect: passing `List<int>`
directly to `dart:html` Blob produced ASCII byte-list text. It now passes a
`Uint8List`. A browser-downloaded XLSX was validated as a Microsoft Excel 2007+
package and passed `unzip -t`; a browser-downloaded PDF passed `file` and
`pdfinfo`. The source OOXML package test, Flutter tests, analyzer, and release
build continue to pass.

These fixes improve export/form correctness but do not change the limitation
that the complete collection, reconciliation, approval-action, check, print,
viewport, and RTL acceptance matrix still requires execution.

The same browser rerun also verified the Reports print callback, no horizontal
overflow at desktop/tablet/mobile viewport sizes, and employee navigation
restriction. These are smoke checks only; they do not imply every page and
financial workflow is complete at every viewport.

The collection flow was then exercised with the isolated admin account. A
shared Form had incorrectly caused request creation to validate the separate
confirmation reference; the create action now performs only its own amount and
settlement checks. An instant EGP 10.00 request was created and confirmed in
the UI. Firestore showed the request as `confirmed`, settlement collected
`1000` minor units, and the destination bank balance increased to `10000974`
minor units. Collection request creation and confirmation writes now include
`updatedAtMillis` for incremental synchronization. Normal collection and the
full partial-allocation matrix remain unverified.

## Firestore-only continuation — 2026-10-26

The active target remains `credixa-422a1`. Firestore Rules and indexes were
deployed without Functions, Hosting, Storage, billing, or service-account
credentials in the Flutter app. A staff-only create allowance for
`treasury_reconciliations` was added and deployed without changing tenant,
role, audit, or financial update protections.

Live verification covered reconciliation adjustments, transfer fees, personal
withdrawal approval metadata, issued-check deduction idempotency, normal and
instant collection confirmation, over-allocation rejection, and manager
approval of an isolated pending expense. The data source now performs a full
collection read when a sync marker has no matching cache. Expense writes also
persist `updatedAtMillis` so pending records remain visible to incremental
approval reads.

This remains a client-transaction architecture: Rules enforce organization
membership and coarse role/state conditions, but cannot prove every
cross-document accounting invariant against a malicious client. Reconciliation,
audit, duplicate-operation IDs, and review controls remain required. Emulator
verification is still blocked by Java `17.0.17` versus the Firebase CLI
requirement for Java 21+.

## Final web-only acceptance note — 2026-10-26

The Web-only acceptance pass used the deployed Firestore Rules and indexes in
`credixa-422a1` and did not run the emulator. The real Brave session visibly
authenticated the isolated admin account, loaded the RTL dashboard, and opened
the approval-center route. Previously executed live UI flows and Firestore
persistence checks cover collection confirmation, treasury reconciliation,
transfer fees, personal-withdrawal approval metadata, issued-check idempotency,
and manager approval of an isolated pending expense.

No architecture claim is upgraded by a successful build alone. Employee
large-operation approval, settlement-reviewer action coverage, and the complete
cross-role/per-viewport browser matrix remain open until they are executed with
usable isolated credentials and visible persistence evidence. Emulator status
for this pass is **DEFERRED_EXTERNAL**, not PASS.

## Targeted web role-matrix status — 2026-10-26

The Firestore-only architecture remained unchanged during the targeted browser
pass. The deployed target was still `credixa-422a1`, and no Functions,
Hosting, Storage, billing, or emulator operation was introduced. Admin login,
RTL dashboard rendering, approval-center routing, and the previously verified
isolated financial workflows remain PASS evidence.

The complete role matrix was previously **BLOCKED_BY_CREDENTIALS**, not
architecturally verified. The isolated credentials were later created/recovered;
the remaining live-role and mobile results are recorded in the later sections.
Emulator status remains **DEFERRED_EXTERNAL**. The current client-transaction
design and its existing limitation—Firestore Rules cannot by themselves prove
every malicious cross-document accounting invariant—remain
unchanged.

## Credential recovery and live-role verification state — 2026-10-26

The target remains `credixa-422a1`; no Functions, Hosting, Storage, billing,
or emulator operation was introduced. The isolated organizations
`E2E_TEST_Credexa_2026_10_24` and `E2E_TEST_OtherOrg_2026_10_24` are present.
Five isolated Auth accounts and their directory/scoped membership records were
verified, including `settlements.review=true` for the reviewer.

Auth and Firestore persistence checks are not a substitute for visible browser
acceptance. The Brave Computer Use session was interrupted while navigating
multiple windows, so employee treasury thresholds, manager approval/rejection,
reviewer self-approval protection, other-organization direct-route/write
denial, and the complete responsive action matrix remain **UNVERIFIED**.
Emulator status remains **DEFERRED_EXTERNAL — Java 21 unavailable**. The
client-transaction design and its limitation—Rules cannot prove every
cross-document accounting invariant against a malicious client—remain
unchanged.

## iOS Simulator validation state — 2026-10-26

The iPhone 17 Pro simulator booted, but the app did not launch because CocoaPods
could not retrieve Firebase iOS SDK 12.19.3 from the CDN (HTTP/2 framing error)
and the fallback cached dependency path stalled while fetching
BoringSSL-GRPC 0.0.37. This does not change the Firestore-only architecture;
no iOS flow is claimed verified. Emulator testing remains
**DEFERRED_EXTERNAL — Java 21 unavailable**.

## Simulator launch verification — 2026-10-26

After the security-gate change, the iPhone 17 Pro simulator launched the app
successfully and displayed the Credexa login screen. This confirms the
Firestore-only client can start on the test simulator; it does not claim that
authentication or financial flows were completed.

## Web role-matrix completion pass — 2026-10-29

The existing local Web session used Firebase project `credixa-422a1` and only
the isolated test organizations. The pass did not deploy Functions, Hosting,
Storage, billing changes, or emulator resources.

The live browser verified authenticated Admin-equivalent, Employee, Manager,
Settlement Reviewer, and Other-Organization sessions. Employee small treasury
operations executed immediately; employee operations above EGP 5,000 remained
pending until manager review; manager approval/rejection was idempotent and the
persisted isolated treasury total ended at EGP 157,005.00. Other-organization
routes returned only that organization's empty/zero-scoped data and protected
manager-only pages.

The reviewer settlement approval matrix is not upgraded to PASS. The visible
settlement form describes manual transaction IDs as optional, while
`FirebaseOperationsDataSource.createSettlement` requires real existing purchase
IDs and validates their brand/allocation. As a result, the reviewer-created
isolated settlement did not persist, no pending reviewer settlement existed to
approve or reject, and the reviewer credit-card page was blank in that browser
session. This is a client/data-source contract gap, not evidence that the
Firestore Rules were bypassed.

The logout route overlay defect was fixed by allowing `AuthGate` to own the
post-sign-out route rather than pushing a second login page. Engineering
validation passed for tests, Web release build, and diff whitespace; analyzer
reported only 26 informational findings. Emulator status is
**DEFERRED_EXTERNAL — Java 21 unavailable and Emulator excluded from this
Web-only pass**. The client-transaction architecture and its limitation remain
unchanged: Firestore Rules enforce tenant/role/state boundaries but cannot by
themselves prove every cross-document accounting invariant against a malicious
client.

## Historical web acceptance evidence before targeted retest — 2026-10-30 (superseded)

The Firestore-only architecture was exercised against `credixa-422a1` using
only the isolated E2E organizations. The visible browser pass verified
immediate versus pending employee treasury operations, manager approval and
rejection idempotency, settlement-reviewer approval/rejection,
self-approval denial, duplicate purchase allocation denial, audit persistence,
reports, exports, print preview, and responsive Operations/Reports rendering at
1440/1024/768/390/360px.

At that point, two application gaps remained: Users creation still received Firestore
`permission-denied` under the deployed rules, and the Navigator-only web shell
does not support direct browser deep links such as `/#reports`, although
internal AppNavigation works. These are web-testable limitations, so the
application is not declared fully complete and the rules were not weakened.

Latest validation passed 9 Flutter tests, analyzer with no errors or warnings
(23 informational findings), the release Web build, and diff whitespace
validation. No Functions, Hosting, Storage, billing, service account, or
Emulator resource was introduced. Emulator status remains
**DEFERRED_EXTERNAL — Java 21 unavailable and Emulator excluded from this
Web-only pass**. Local Firebase CLI revalidation is awaiting
`firebase login --reauth` because its credential expired; the earlier Rules and
Indexes deployment remains the recorded deployment for the target project.

## Targeted web completion retest — 2026-10-30

The prior Users-create permission failure was caused by the client transaction
implicitly reading the root membership directory while the deployed rules only
allow the scoped manager read path. The repository now performs a scoped
duplicate preflight and commits the root directory plus scoped member record in
one Firestore batch. This preserves tenant authorization and avoids weakening
the rules. The visible manager flow created an isolated employee membership and
the result survived refresh.

The Web shell now maps supported `AppDestination` values in
`onGenerateRoute`/`onUnknownRoute` and wraps direct authenticated pages with the
same security/auth gates as internal navigation. Direct `/#users` and
`/#reports` were both verified in the browser.

No Functions, callable Functions, Storage, Hosting, service-account
credentials, or billing changes were introduced. Emulator verification remains
**DEFERRED_EXTERNAL — Java 21 unavailable and Emulator excluded from this
Web-only pass**.

The isolated E2E email identifiers and generated temporary passwords are stored
only in the ignored local `.env.e2e.local` file (mode 600). They are not part of
the Flutter Web bundle, tracked source, or production data. Firebase Auth
synchronization must still be verified by a successful UI login for each
account. The first visible attempt with the stored isolated Admin pair was
rejected by Firebase as an invalid email/password pair, so the local file is
currently a credential target, not evidence of synchronized Auth state.

## Final web-only acceptance closure — 2026-10-30

The credential-recovery gap is superseded. The five isolated Auth accounts were
used through the running Flutter Web app against `credixa-422a1`; passwords
remain only in `.env.e2e.local`, which is ignored and local-only. The final
admin, manager, employee, and reviewer scoped member records were created
through the visible Users workflow in `E2E_TEST_Credexa_2026_10_24`. The other
account remained isolated through its separate `membership_directory`
organization record.

Visible acceptance evidence includes employee immediate/pending treasury
thresholds; manager one-time approval, rejection reason, and balance
persistence; reviewer settlement/collection visibility plus the previously
verified approve/reject/self-approval and duplicate-allocation guards; OtherOrg
tenant isolation and manager-only denial; authenticated `/#users` and
`/#reports` routes; audit, notifications, reports, XLSX, PDF, browser print;
and the required desktop/tablet/mobile RTL viewport checks.

The logout defect is fixed: Firebase auth state now recreates `AuthGate`
immediately instead of leaving a stale login page above the application.
Engineering results are 9/9 Flutter tests, successful Web release build, and
clean `git diff --check`. Analyzer exit 1 is limited to 24 informational
style/deprecation diagnostics and contains no error or warning diagnostics.
Firestore Rules and indexes remain deployed to `credixa-422a1`; no Functions,
Hosting, Storage, billing, service-account credential, or production-data
operation was introduced.

Emulator status remains exactly **DEFERRED_EXTERNAL — Java 21 unavailable and
Emulator excluded from this Web-only pass**. This is the only intentionally
deferred external validation item; it is not represented as an emulator pass.

## Web-only persistence verification closure — 2026-10-30

The Firestore-only architecture was revalidated through the existing Web
client. Catalog mutations continue through the scoped organization repository
and data-source layers; no callable Function, Storage path, service-account
credential, or rule relaxation was introduced. The incremental reader now
queries with `updatedAtMillis >= lastSyncAt`, preserving writes that occur in
the same millisecond as the local cache marker.

Visible UI verification covered provider, brand, POS, receiving-company,
bank-account, expense-category, and beneficiary edits. Brand deactivation and
reactivation survived full browser reloads, proving persisted state rather
than only widget state. Flutter tests (9/9), the release Web build, and diff
whitespace validation pass; analyzer has only 24 info-level diagnostics.
Emulator status remains **DEFERRED_EXTERNAL — Java 21 unavailable and Emulator
excluded from this Web-only pass**.

## Delete persistence verification — 2026-10-30

The only financial delete action exposed by the current Web UI is purchase
deletion. It was exercised twice with the visible confirmation dialog against
isolated E2E records. The resulting soft-delete/audit path persisted through a
full browser reload and reversed the card balance exactly. No production
document was deleted and no alternate direct Firestore write was used to
simulate the workflow.
