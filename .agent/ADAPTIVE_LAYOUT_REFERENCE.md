# Adaptive Layout Reference

A portable, evidence-based guide to tablet / landscape / wide-web layout, extracted from a
production Flutter application (**TMT Track**, a GPS fleet-tracking app) that ships Android,
iOS and Web from a single codebase.

This document is written to be **self-contained**. An agent with no access to the source
repository should be able to read it and apply the rules to a *different* application that
already has a good portrait experience.

---

## How to read the labels

Every non-trivial statement carries one of three labels:

| Label | Meaning |
|---|---|
| **[CODE]** | Observed by reading the source. The referenced file and widget/helper name are given so the behaviour can be traced. |
| **[VERIFIED]** | Confirmed by running the app at a specific window size. **No finding in this document is `[VERIFIED]`** — see *Limitations*. |
| **[RECOMMENDED]** | Advice for the target application. Not observed behaviour. Never present it as a rule the reference app follows. |

> **Runtime inspection was not performed.** No emulator, device, or browser was launched.
> Every measurement below is derived from code. Treat all widths/heights as *declared intent*,
> not as observed pixel output.

---

## A. Summary of the layout approach

### A.1 The one-sentence model — [CODE]

> **A single boolean — `context.isAppLandscape` — selects between two entirely separate
> widget trees per screen, and a second class of booleans (`context.isTablet`, `context.isMobile`,
> `context.deviceType()`) tunes sizes *within* each tree.**

Source: `lib/core/ui/widgets/responsive/responsive_config.dart:119-143`

```dart
bool get isAppLandscape {
  final isDesktopPlatform =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  if (kIsWeb || isDesktopPlatform) {
    return screenWidth >= ResponsiveConfig.landscapeBreakpoint;   // 1080
  }
  if (!isLandscape) return false;          // physical portrait -> always mobile layout
  const double nativeLandscapeThreshold = 840.0;
  return screenWidth >= nativeLandscapeThreshold;                 // 840
}
```

Consequences that matter for the target app:

- **Landscape is a *mode*, not a rotation.** A physically-landscape phone narrower than
  840 px still gets the portrait/phone layout. A 1000 px-wide web browser window also gets
  the phone layout. This is the single most important rule to copy, because it is what
  stops a tablet or a narrow browser window from receiving a broken half-desktop layout.
- **The threshold differs by platform** (840 native vs 1080 web/desktop). This is a genuine
  inconsistency in the reference app — see §F — but the *intent* (native needs a lower
  bar than desktop) is sound and worth reproducing deliberately.
- **`isAppLandscape` is deliberately independent of `screenWidth` alone**, so the app does
  not depend on `MediaQuery` orientation reporting, which is unreliable in browser windows.

### A.2 Three-tier scaling — [CODE]

`currentDesignSize` (`responsive_config.dart:151-165`) returns a different *design canvas*
depending on the resolved mode, and it is wired into the app shell
(`lib/app/base/app/ui/view/app_view.dart:31`, `PlayxScreenSettings(designSize: context.currentDesignSize)`).

| Mode | Design size | Applies when |
|---|---|---|
| Mobile | `375 × 812` | width < 600 |
| Tablet | `768 × 1024` | 600 ≤ width, portrait mode |
| Web | `1440 × 960` | `isAppLandscape` |

The design size drives `.r` / `.sp` scale factors used pervasively (e.g. `16.r` padding).
`ensureScreenSize: true` is set, so the screen metrics are normalised to that design canvas.

### A.3 Sizing helpers — [CODE]

| Helper | Location | Behaviour |
|---|---|---|
| `16.r`, `16.wBox`, `16.boxH`, `8.r` | playx `ScreenUtil` extensions | Scales by the *smaller* of width/height ratio against the design size. The dominant idiom. |
| `n.clampedR` | `responsive_config.dart:307-311` | Same as `.r` but **capped at 1.1 × the design value**. Prevents runaway growth on 4K / ultra-wide. |
| `n.sp` | ScreenUtil | Scales with width ratio only. |
| `ResponsiveConfig.maxPortraitWidth = 600` | `responsive_config.dart:26` | Intended to stop the phone layout stretching on portrait tablets. **Dead in practice** — see §F. |
| `PortraitConstraint` | `responsive/portrait_constraint.dart` | Applies `Center + ConstrainedBox(maxWidth: 600)` when not landscape. Only wired via `CustomScaffold(attachPortraitConstraint: true)`, which **no call site sets**. |

### A.4 What did *not* work — [CODE]

- `CustomResponsiveBuilder` (`responsive/widgets/custom_responsive_builder.dart`) implements a
  full mobile/tablet/desktop builder + debounced metric observer. **It is never used by any screen.**
- `DeviceType.valueWhen()` / `context.valueWhen(mobile:, tablet:, desktop:)` exists and is used,
  but only for *size* tweaks (padding, spacing), never for structural branching.
- `DeviceInfo` / `OrientationType` are defined but only `CustomResponsiveBuilder` consumes them.

**Lesson [RECOMMENDED]:** do not build a general responsive framework before you know your
screen inventory. The reference app's effective system is one boolean plus a handful of
size functions; the richer abstractions are unused.

---

## B. Breakpoint and layout-rule tables

### B.1 Declared system breakpoints — [CODE]

All in `lib/core/ui/widgets/responsive/responsive_config.dart`.

| Constant | Value | Line | Used for |
|---|---|---|---|
| `mobileBreakpoint` | `600.0` | 9 | `deviceType()` lower bound |
| `tabletBreakpoint` | `1080.0` | 10 | `deviceType()` upper bound |
| `desktopBreakpoint` | `1080.0` | 11 | `getResponsiveWidth()` cap |
| `landscapeBreakpoint` | `1080.0` | 16 | **The** layout switch on web/desktop |
| `nativeLandscapeThreshold` (local) | `840.0` | 141 | **The** layout switch on native landscape |
| `maxPortraitWidth` | `600.0` | 26 | Intended portrait cap (unused) |
| `mobileDesignSize` | `375 × 812` | 19 | ScreenUtil canvas, phone |
| `tabletDesignSize` | `768 × 1024` | 20 | ScreenUtil canvas, portrait tablet |
| `webDesignSize` | `1440 × 960` | 21 | ScreenUtil canvas, landscape/desktop |
| `railWidth` | `72.0` | 28 | Declared; the `BuildContext` extension re-declares it |
| `extendedRailWidth` | `221.0` | 29 | Declared; largely shadowed |
| `drawerWidth` | `300.0` | 32 | Declared |
| `animationDuration` | `300 ms` | 34 | Not used as a global default |

### B.2 The two-tier device classifier — [CODE]

`responsive_config.dart:167-196`

```
screenWidth < 600   → DeviceType.mobile
600 ≤ width < 1080  → DeviceType.tablet
width ≥ 1080        → DeviceType.desktop
```

Always width-based; the code comments explicitly reject `shortestSide` detection as
unreliable in the 500–900 px band. `context.isMobile` / `isTablet` / `isDesktop` delegate here.

### B.3 Default grid column ladder — [CODE]

Two independent declarations of the same ladder:

| Declaration | Location | Map |
|---|---|---|
| `ResponsivePagedSliverView` default | `lib/core/ui/widgets/custom_sliver_pagination_list.dart:54` | `{1400: 3, 840: 2, 0: 1}` |
| `context.crossAxisCount()` | `lib/core/utils/extensions.dart:188-196` | `{1400: 3, 840: 2, 0: 1}` (params `wideBreakpoint`, `mediumBreakpoint`) |

Resolution: sort keys descending, return the count for the first breakpoint `width >= bp`,
else `1`. **Uses full window width, not the content-area constraints** — a weakness, see §5.4.

### B.4 All page-local breakpoints observed — [CODE]

These are the numbers an adopting agent must know about, because they are *not* the system
breakpoints and they are inconsistently applied.

| Value | Files | Purpose |
|---|---|---|
| `1100` | `view/widgets/content_tabbed_page_header.dart:37` | Header collapses to two stacked rows below this width |
| `1400` / `840` | grid maps (12+ call sites) | Default card grid 3 / 2 / 1 |
| `900` | `simple_vehicles_view.dart:162`, `vehicles_shell_portrait_view.dart:83`, `vehicle_integrations_list_view.dart:19`, `base_paged_controller.dart:37`, `places_controller.dart:38`, `waste_controller.dart:31` | Alternate 2-column gate and default `isTableView` seed |
| `1000` | `module_settings_view.dart:88-90`, `active_modules_web_list_widget.dart:29` | List ↔ 2-column grid |
| `1200` / `1450` / `1700` | `map/ui/map/views/shared/map_surface_widget.dart:173-213` | Map panel / info-card width ladder |
| `600` (height) | `places/ui/groups/group_details/.../group_details_view.dart:121` | Info panel 40 % vs 30 % |
| `720` | `state/empty_data_widget.dart`, `state/error_widget.dart`, `login_view.dart:58`, `jobs/.../build_details_view_card.dart:16` | Empty/error typography; login gutter; detail card split |
| `1000` / `1600` | `history/.../build_map_with_panel.dart:55-61` (duplicated in `build_map_with_controls.dart:196-202`) | History info panel width ladder |
| `1050` | `map/.../build_map_info_responsive_pair.dart:21` | Row vs column inside a 300 px panel |
| `1400` | `map/.../street_view/build_street_view_card.dart:22-33` | Street-view card fixed size |
| `340` / `980` | `dashboard/.../dashboard_stats_cards_section.dart:11-12` | Stat card 1 / 2 / 5 per row |
| `840` | `Dimens.bigScreenWidthThreshold` (`dimens.dart:65`) | Legacy threshold, used by the speed dial |

**`900` deserves emphasis — [CODE].** `BasePagedController.onInit()` seeds
`isTableView.value = ScreenUtil().screenWidth > 900`
(`lib/core/ui/widgets/view/controller/base_paged_controller.dart:37`).
So between 900 px and 1080 px the app is in **portrait mode but with table view selected**,
a combination the portrait branch is not designed for.

### B.5 Spacing and content-width tokens — [CODE]

| Token | Value | Where |
|---|---|---|
| Page gutter | `16.r` (or raw `16` in older code) | Nearly every details/form screen |
| Card gap inside a 2-column row | `16.r` / `16.wBox` | `Expanded` + `16` gap is the house pattern |
| Section gap | `16.r` … `24.r` | Varies by screen |
| Header inline padding | `16.r` horizontal, `12.r` top | `ContentTabbedPageHeader`, `_GenericPagedHeader` |
| Header row gap | `8.r` | Same |
| Search field max width | `260.r` (tabbed), `300.r` (`ContentLandscapeViewPage`), `300` (`GenericPagedView`), `308` (`ContentTabbedPageSearchBar` fallback) | Four different values — inconsistency |
| Sidebar width, generic | `context.width * .15` | `SidePanelLayoutView` (`side_panel_layout_view.dart:151`) |
| Sidebar width, multi-step form | `min(240.r, context.width * .14)` in jobs/reports/maintenance-create; `context.width * .17` in maintenance-edit | Inconsistent — see §F |
| Max content width (used) | `1480.r` (login), `760.clampedR` (forgot password), `700.0.r` (places group create), `327.0.clampedR` … `479.0.clampedR` (map pickers) | No single global "readable width" token |
| Max content width (unused) | `maxPortraitWidth = 600` | Intended, never applied |

### B.6 Typography and control resizing — [CODE]

| Element | Portrait | Landscape | Mechanism |
|---|---|---|---|
| App bar height | `kToolbarHeight` (56) | `44.0` | `custom_app_bar.dart:69` |
| App bar title | `16.0` (raw, unscaled) | `16.sp` | `custom_app_bar.dart:151` |
| App bar leading width | `40` (Android portrait) / `null` | `52.0` | `custom_app_bar.dart:165` |
| App bar divider | `kToolbarHeight.r − 20.r` tall | `16.0` tall | `custom_app_bar.dart:124-126` |
| Logo in app bar | `74.0.r × 24.0.r` | `74.0 × 24.0` (raw dp) | `custom_app_bar.dart:109-110` |
| Content page title | `20` (legacy) / `24.sp` | `24.sp` | `content_landscape_page_view.dart:175`, `content_tabbed_page_header.dart:46` |
| List item detail font | `12` | `14` | `dashboard/.../event_item_widget.dart:137` |
| `DetailItem` font | `13.sp` | `14.0.sp` | `components/detail_item.dart:92-96` |
| `DetailItem` icon | `16.r` | `18.0.r` | `detail_item.dart:116-120` |
| Empty/error message font | `16.sp` below 720 px | `20.sp` at/above 720 px | `empty_data_widget.dart:65,141` |
| Icons / padding | `.r` scaled | raw dp in chrome, `.r` in content | mixed — see §F |

**Pattern to copy [RECOMMENDED]:** in landscape, chrome (app bar, rail, chrome buttons)
stops scaling and uses fixed dp, while content keeps `.r`. The rationale is that the
landscape design canvas is 1440 px wide, so `.r` would shrink content unnecessarily on a
1920 px display. The `DrawerScale` helper formalises this:

```dart
// lib/app/base/app/ui/view/drawer/layout/drawer_layout_scale.dart
double r(double value) => isLandscape ? value : value.r;
double sp(double value) => isLandscape ? value : value.sp;
```

---

## C. Complete screen inventory

64 registered routes (`lib/core/navigation/src/app_routes.dart`) plus 10 in-app
non-routed screens. Every row below was read.

Legend for *Wide/landscape*:
- **PW** = `CustomOrientationWidget` split into `buildPortrait` / `buildLandscape`
- **if** = inline `if (context.isAppLandscape)` ternary
- **Base** = delegates to a shared base view that does the branching

### C.1 Shell / auth / setup

| # | Screen | Category | Narrow layout | Wide / landscape | Switching condition | Main files |
|---|---|---|---|---|---|---|
| 1 | Splash | Setup | Column, centred logo, `height*0.4` Lottie strip | **same** (no branch) | — | `base/splash/.../splash_view.dart` |
| 2 | Onboarding | Setup | `CustomScaffold(includeAppBar:false)` → page view | **same** | — | `base/onboarding/.../onboarding_view.dart` |
| 3 | Choose language | Setup (onboard sub) | `CustomResponsiveBuilder`-style branch, `isMobile ? 1 : n` | wider grid | `context.isMobile` (600) | `base/onboarding/.../language/choose_language_view.dart` |
| 4 | Choose theme | Setup (onboard sub) | same as above | same | `context.isMobile` | `.../theme/choose_theme_view.dart` |
| 5 | Force update | Setup | Column, `height*0.36/.33` animation | same height branch, no width branch | `context.height >= 900` | `base/update/.../update_view.dart`, `build_update_animation_widget.dart:9` |
| 6 | Login | Auth | `BuildLoginView` single centred card | `SafeArea` → `ConstrainedBox(maxWidth: 1480.r)` → `Row[flex 8|10 login pane, 24.r, flex 10 onboarding]`; pane `ClipRRect(24.r)` with `start/end 56.r, top 48.r, bottom 32.r` | `context.isAppLandscape` | `base/auth/.../login_view.dart:44,158` |
| 7 | Login (biometric) | Auth | Card | same landscape pane | `isAppLandscape` | `.../build_login_with_biometric_view.dart` |
| 8 | Forgot password (3 steps) | Auth | `PageView` of 3 steps in one centred card | card wrapped in `Center`; container `maxWidth: 760.clampedR`; `PageStorageKey` keeps step | `isAppLandscape` (card `Center`) | `.../forget_password_view.dart:129,148` |
| 9 | Change password | Auth dialog | **Bottom sheet** on `isAppPortrait && !isTablet` | `Dialog`, `maxWidth: 696.r`, `maxHeight: height*0.85`, `viewInsets` honoured | `context.isAppPortrait && !context.isTablet` ⚠ off-system | `settings/ui/change_password/view/dialog/change_password_dialog.dart:12,59,116` |
| 10 | Logs (Talker) | Debug | `CupertinoPage` + `TalkerScreen` | same | — | `app_pages.dart:542-551` |

### C.2 Home shell branches

| # | Screen | Category | Narrow layout | Wide / landscape | Switching condition | Main files |
|---|---|---|---|---|---|---|
| 11 | Dashboard | Dashboard | `CustomScrollView`, `padding 12.r`, FAB = speed dial | `Expanded/Expanded` rows; events `flex 3` + fleet `flex 2` at `height*0.65`; FAB suppressed | `isAppLandscape` for structure, **`isWebLayout` for FAB** ⚠ | `dashboard/.../dashboard_view.dart:24,110,126-180` |
| 12 | Map (vehicles) | Map | `SlidingUpPanel` `maxHeight = height*dimens.mapInfoHeightFactor` (`.49/.52/.56`), `minHeight = height*0.23` (or `0.29`) | `Stack[map, controls, Row[left card, right column]]`; widths from the 1200/1450/1700 ladder; panel hidden below 1200 (`isPanelOnly`) | `isAppLandscape` (PW) | `map/.../shared/map_surface_widget.dart:69-72,134-213` |
| 13 | Map (trips) | Map | same `SlidingUpPanel` | same ladder | `isAppLandscape` | `map/ui/ujrah_vehicles/` |
| 14 | Map (waste) | Map | same | same | `isAppLandscape` | `map/ui/waste_containers/` |
| 15 | Map history | Map + list | `SlidingUpPanel` `maxHeight = height*0.52`, `minHeight 0`, OPEN | rounded `Container` + `Stack[controls, SafeArea(Card)]`, slide-in `Offset(0.1,0)`/`easeOutBack` 400 ms; panel width ladder `600/1000/1600` | `isAppLandscape` (PW) | `history/.../map_history_view.dart`, `build_map_with_panel.dart:19-117` |
| 16 | Vehicles | List | `CustomScaffold` + `BuildSimpleVehiclesPortraitBody` (search + `ToggleSwitch` chips + list) | `ContentTabbedLandscapeViewPage<VehicleFilterType>` header + table or grid; grid `1400/900/1400` | `isAppLandscape` | `vehicles/.../simple_vehicles_view.dart:159-167`, `shell/vehicles_shell_{portrait,landscape}_view.dart` |
| 17 | Advanced vehicles | List | **dead code** — `return const SizedBox.shrink()` | — | — | `vehicles/.../advanced_vehicles_view.dart:10` |
| 18 | Places (Markers / Zones / Groups) | List | `CustomScaffold(useSafeArea:false)` + `ToggleSwitch` + `CustomSearch(maxWidth: context.width)` + `TabBarView` | `ContentTabbedLandscapeViewPage<PlacesLayerType>` with count chips + `CustomPagingTableView` or grid | `isAppLandscape` | `places/.../places_view.dart:141,386` |
| 19 | Events + Alerts (tabs) | List | manual tab bar + search + `ResponsivePagedSliverView` `{1400:3,840:2,0:1}` | `ContentTabbedLandscapeViewPage` + tables/grids, grid `{900:3,600:2,0:1}` ⚠ | `isAppLandscape` | `events/.../events_view.dart:12,72,158,172` |
| 20 | Event rules + Alert rules (tabs) | List | manual tab bar + search + grids `{1400,840}` | `CustomScaffold(includeLogo:false, breadcrumbs)` + `ContentTabbedLandscapeViewPage`, grid `{900,600}` ⚠ | `isAppLandscape` | `events/.../event_rules_view.dart:58,122,136` |
| 21 | Alerts (list) | List | reused inside Events tab 2 | same | inherits | `events/ui/alert_rules/rules/` |
| 22 | Reports (Generated / Scheduled) | List | manual `Column` + tab switch + search + list; FAB | `ContentTabbedLandscapeViewPage` with `customToggleBuilder`; `endActionButton` | `isAppLandscape` | `reports/.../reports_view.dart:60,76-79` |
| 23 | Ujrah orders (trips) | List | `SearchFilterBar` + `ResponsivePagedSliverView` `{1400,840}`; **filter button commented out** ⚠ | `GenericPagedView<TripInfo>.withController` + table or grid | `isAppLandscape` | `ujrah/.../trips_view.dart:42,49-54` |
| 24 | Waste containers | List | `CustomScaffold` + `SearchFilterBar` + `ResponsivePagedSliverView` | `GenericPagedView<WasteContainer>` + table or grid | `if (context.isAppLandscape) _buildLandscape(...) : _buildPortrait(...)` | `waste/.../waste_view.dart:8,60` |
| 25 | Bus routes (Rehla) | List | `CustomScaffold` with search in the **app bar** *and* a second `SearchFilterBar` in the body ⚠ | `GenericPagedView<BusRoute>` + table or grid | `isAppLandscape`; toggle gate `context.width < 840` ⚠ | `rehla/.../bus_routes_view.dart:16-34,69` |
| 26 | Vehicle groups | List | `VehicleGroupsPortraitView` (no `CustomScaffold`) | `GenericPagedView<VehicleGroup>(useScaffold:false)` | `isAppLandscape` | `vehicle_groups/.../vehicle_groups_view.dart:27`, `layout/portrait/…:136-143` |
| 27 | Drivers | List | `SearchFilterBar` + `ResponsivePagedSliverView`; **no ViewToggle** ⚠ | `GenericPagedView<Driver>.withController` + table or grid | `isAppLandscape` | `driver/.../drivers_view.dart:48,58` |
| 28 | Jobs | List | `CustomScaffold` + `BuildJobsListWidget` + FAB; toggle gated `width >= 840` | `GenericPagedView<Job>.withController` + table or grid | `isAppLandscape` | `jobs/.../jobs_view.dart:14-20,43` |
| 29 | Maintenances | List | `CustomTourView` + `buildAppBar` + list + FAB; toggle **always** shown ⚠ | `GenericPagedView<Maintenance>` + table or grid | `isAppLandscape` | `maintenances/.../maintenances_view.dart:24,56` |
| 30 | Event triggers (in Settings) | List | `SettingsMobileView` tab body, `SliverMainAxisGroup` + `ResponsivePagedSliverView {1400,840}` | `EventTriggersWebView` = fixed header + table + fixed pagination footer | `isAppLandscape` | `settings/.../event_triggers_{mobile,web}_view.dart` |
| 31 | Vehicle integrations | List | `BuildVehicleIntegrationsListContent(crossAxisCount:1, showTitle:true)` | `VehicleIntegrationsListWidget`, counts `1400/900/1400`; details open as a **modal** (`maxWidth: width*0.483`) | `if (context.isAppLandscape && widget.useModal)` | `vehicle_integrations/.../vehicle_integrations_view.dart:29-45`, `vehicle_integrations_list_view.dart:16-27` |
| 32 | Settings | Settings | `SettingsMobileView`: tab strip `AppScrollableTabBar` + `TabBarView`, per-tab `CustomScrollView` | `SettingsWebLayout` = `SidePanelLayoutView<SettingsTabs>` (sidebar `width*.15`) + content card; `attachBreadcrumb: true` | `isAppLandscape` (PW host) | `settings/.../settings_view.dart:27,52`, `settings_web_view.dart` |
| 33 | Module settings | Settings | `ListView.separated` + `ActiveModulesActionsFab` | `AlignedGridView.count(crossAxisCount:2)` + `ActiveModulesActionsWidget` in `actions` | `isAppLandscape` for actions, **`width > 1000`** for grid ⚠ | `settings/.../module_settings_view.dart:16,22,88-90` |

### C.3 Details screens

| # | Screen | Category | Narrow layout | Wide / landscape | Switching condition | Main files |
|---|---|---|---|---|---|---|
| 34 | Vehicle details | Details | header card + scrollable tab buttons + `TabBarView` (map/info panes) | `IntrinsicHeight(Row[Expanded(flex 1004) ObjectCard, Expanded(flex 340) SimCard])` + options block; `padding 16.r` | `isAppLandscape` (PW) | `vehicles/.../vehicle_details_view.dart`, `build_vehicle_details_landscape_body.dart:16-48` |
| 35 | Driver details | Details | `NestedScrollView` + tab bar + `TabBarView` (Overview / Vehicles); FAB assign | `Row[Expanded DriverCard, 16.wBox, Expanded OperatorCard]` then vehicles body; `paddingAll(16)`; **no landscape action replacement** ⚠ | `final isLandscape = context.isAppLandscape` | `driver/.../driver_details_view.dart:9,24-37,64-86` |
| 36 | Job details | Details | `NestedScrollView` + `TabBarView` (Info / Vehicle / Checkpoints); app-bar actions + FAB | all sections in one `CustomScrollView`; `Row[Expanded General, 16.r, Expanded Vehicle]` then `Row[Expanded Driver, 16.r, Expanded Operator]`; **no landscape action replacement** ⚠ | `isAppLandscape` (PW, `details_view.dart:10`) | `jobs/.../details_view.dart:84-120` |
| 37 | Maintenance details | Details | header + **pinned** `SliverPersistentHeader` tab bar (`min=max=47.5.r`) + `TabBarView` (3 tabs) | `Row[Expanded Overview, 16.r, SizedBox(340.r) Assets]` + files section; header card holds the actions | `isAppLandscape` | `maintenances/.../maintenance_details_view.dart:10,42-58,107-128,349` |
| 38 | Event details | Details | `AppScrollableTabBar` (Info / Rule) + `TabBarView` of `ListView`s | single `ListView(16)`: `Row[Expanded Info, 16.r, Expanded Object]` then full-width Rule | `isAppLandscape` (PW) | `events/.../event_details_view.dart:82-94` |
| 39 | Alert details | Details | `ColoredBox(cardColor)` + `AppScrollableTabBar` (2) + `TabBarView`; app-bar delete button | `IntrinsicHeight(Row[Expanded Info, 16.r, Expanded Object])` + rule; delete moves into the landscape header; `fieldColumns: isLandscape ? 3 : 1` | `isAppLandscape` (PW) | `events/.../alerts/details/views/components/alert_details_{portrait,landscape}.dart` |
| 40 | Event rule details | Details | same as 39 | same, `Row[Expanded Info, 16.r, Expanded (Condition \| Notifications)]` | `isAppLandscape` | `events/.../event_rules/details/views/components/*.dart` |
| 41 | Alert rule details | Details | same as 39 | same | `isAppLandscape` | `events/.../alert_rules/details/views/components/*.dart` |
| 42 | Waste container details | Details | `Column`: card header + button tabs + `Expanded` tab content; app-bar actions; **full tab set** | `CustomScrollView` → `IntrinsicHeight(Row[Expanded GeneralInfo, 16.r, Expanded Map])` + tabs **reduced to 2** ⚠ + sliver body | `isAppLandscape` (PW) | `waste/.../waste_container_details_view.dart:37-60,83-142` |
| 43 | Ujrah trip details | Details | card header + tab bar + `TabBarView` (2) | `Row[Expanded(flex 3) Overview+Timeline, 16.r, Expanded(flex 2) driver+vehicle]` | `isAppLandscape` | `ujrah/.../trip_details_view.dart:9,149-196` |
| 44 | Bus route details (Rehla) | Details | `NestedScrollView` + pinned tab bar (`47.5.r`) + `TabBarView` (3); operator card commented out ⚠; app-bar actions + FAB | all sections stacked full width in `ListView(shrinkWrap)`; **no 2-column split**; app-bar actions and FAB both `null` ⚠ | `isAppLandscape` | `rehla/.../bus_route_details_view.dart:9,72-126` |
| 45 | Vehicle group details | Details | `NestedScrollView` + info card + vehicles tab; icon-only app-bar Edit/Delete chips; FAB assign | `Column` + info card `isLandscape:true` (bigger icon/title) + vehicles body; actions render **inside the card** | `isAppLandscape` | `vehicle_groups/.../group_details_view.dart:29-86` |
| 46 | Marker details (Places) | Details | custom app bar + header card + tabs (Info / Map) | `Row(spacing 8.r, crossAxisAlignment: stretch)[Expanded Info, Expanded Map]`; info panel owns its own `SingleChildScrollView`; **uses `context.width` inside `Expanded`** ⚠ | `isAppLandscape` (PW) | `places/.../marker_details/.../landscape_marker_details_content.dart` |
| 47 | Zone details (Places) | Details | details-only + custom app bar | `Row[Expanded LandscapeSidePanel, Expanded Map]`, gap `8.r`, outer `16` | `isAppLandscape` (PW) | `places/.../landscape_zone_details_content.dart:16-43` |
| 48 | Group details (Places) | Map master-detail | `SlidingUpPanel` `maxHeight = height*0.5` over the map | `Row[Expanded Map, AnimatedSwitcher panel]`; panel `width = height<600 ? width*0.4 : width*0.3` | `isAppLandscape` (PW) | `places/.../group_details_view.dart:28-128` |
| 49 | Report details | Details | `Stack[WebView, Obx(CenterLoading)]` | **same — no branch** (the HTML report is fluid) | — | `reports/.../report_details_view.dart:8-38` |
| 50 | Profile | Account | `CustomScrollView` + `SliverList` of 3 cards | **same — no branch, no max width** ⚠ | — | `profile/.../profile_view.dart:8-116` |
| 51 | Vehicle integration details | Details | `OptimizedScrollView` + `Row[Expanded check, 16.r, Expanded heartbeat]` | **same — no branch** | — | `vehicle_integrations/.../vehicle_integration_details_view.dart` |
| 52 | Checkpoint details | Details (nested) | embedded in job details; no scaffold, no branch | same | — | `jobs/.../checkpoints/details/view/checkpoint_details_view.dart` |

### C.4 Forms / create / edit

| # | Screen | Category | Narrow layout | Wide / landscape | Switching condition | Main files |
|---|---|---|---|---|---|---|
| 53 | Job create / edit (multi-step) | Form | `CustomScaffold` + vertical stepper + `Expanded(PageView)`; bottom action row hidden by `KeyboardVisibilityBuilder` | `SidePanelLayoutView<JobStep>` — sidebar `min(240.r, width*.14)`, vertical stepper, content card; **no action bar** ⚠ | `isAppLandscape` | `jobs/.../job_form_shell.dart:30-101` |
| 54 | Report create (multi-step, 5) | Form | stepper + `PageView`; **field rows always 2-up** ⚠ | `SidePanelLayoutView<ReportStep>`, sidebar `min(240.r, width*.14)` | `isAppLandscape` | `reports/.../create_report_view.dart:9-68` |
| 55 | Maintenance create | Form | stepper + `PageView` | `SidePanelLayoutView`, sidebar `min(240.r, width*.14)` | `isAppLandscape` | `maintenances/.../create_maintenance_view.dart:9-73` |
| 56 | Maintenance edit | Form | stepper + `PageView` | `SidePanelLayoutView`, sidebar **`width*.17`** ⚠ divergent | `isAppLandscape` | `maintenances/.../edit_maintenance_view.dart:9-88` |
| 57 | Alert rule create / edit | Form | `Form` + `ListView`; `stickyActions: true` → fixed footer | same form, `Row` + `Expanded` pairs; **`stickyActions` dropped** ⚠ | `isAppLandscape` | `events/.../alert_rule_form_shell.dart:37,52` |
| 58 | Event rule create / edit | Form | same as 57 | same as 57 | `isAppLandscape` | `events/.../event_rule_form_shell.dart` |
| 59 | Event trigger create / edit (2 tabs) | Form | `DefaultTabController(2)` + `TabBarView` + bottom actions; main tab = `CustomScrollView` | main tab = `IntrinsicHeight(Row[flex 630 settings, VerticalDivider, flex 460 table])`; modal `1170.r` ⚠ | `isAppLandscape` | `settings/event_triggers/.../build_event_trigger_form_main_tab.dart:45-74` |
| 60 | Marker create / edit (Places) | Form | map + `SingleChildScrollView` (shared `ScrollController`) | map + form column; **scroll offset survives rotation** ✅ | ternary on `isMapFullscreen` then `isLandscape` | `places/.../create_marker_view.dart:70-87` |
| 61 | Zone create / edit (Places) | Form | same as 60 | same | same | `places/ui/zones/...` |
| 62 | Group create / edit (Places) | Form | `SingleChildScrollView` + fixed `Row` of 2 `Expanded` buttons | `Center + ConstrainedBox(maxWidth: 700.0.r)` — **still single column** ⚠ | `isAppLandscape` | `places/.../create_group_view.dart:25-27,123-124` |
| 63 | Vehicle group create / edit | Form | `Expanded(SingleChildScrollView)` + `CancelConfirmButtons` | **identical — single column stretched, no `Center`, no `maxWidth`** ⚠ | none | `vehicle_groups/.../create_vehicle_group_view.dart:16-49` |
| 64 | Waste container edit | Form | `Expanded(SingleChildScrollView)` + footer buttons | header `Row` with right-aligned compact buttons + `Expanded(form)` — **form not scrollable** ⚠ | `if (context.isAppLandscape)` | `waste/.../edit_waste_container_view.dart:15-92` |
| 65 | Checkpoint create / edit (modal) | Form | map `maxHeight = height*0.8`, sheet `minHeight: 500.r` | map `maxHeight = height*0.55` (**inverted** ⚠), `minHeight: 600.r` | `isAppLandscape` (sizing only) | `jobs/.../build_checkpoint_form_widget.dart:21,45` |
| 66 | Edit report schedule (modal) | Form | `maxHeight = height*0.9 − viewPadding.bottom − viewInsets.bottom`; `SingleChildScrollView` + fixed 64.r footer | same (already correct) | none — **only form with correct keyboard math** | `reports/.../build_edit_report_schedule_body.dart:16` |
| 67 | Create / update bus route (Rehla) | Form | accordion expand/collapse | accordion chrome hidden; body `CustomScrollView` | `isAppLandscape` | `rehla/.../update_bus_route/view/…:33,78,86` |
| 68 | Create / edit rest point (Rehla) | Form | fixed `1171.clampedR × 688.clampedR` card ⚠ **exceeds a 375 pt phone** | same | none | `rehla/.../create_edit_rest_point_view.dart:16-17` |
| 69 | Assign vehicle to driver (modal) | Form | `maxWidth = width*0.95`, `maxHeight: infinity` ⚠ | `maxWidth = width*0.7`, `maxHeight = height*0.85` | `isAppLandscape` | `driver/.../assign_vehicle_to_driver_modal.dart:267,498` |

### C.5 Media, guest and utility screens

| # | Screen | Category | Narrow layout | Wide / landscape | Switching condition | Main files |
|---|---|---|---|---|---|---|
| 70 | Live video | Media | `Stack[WebView, loading, close FAB topEnd, refresh FAB bottomEnd]` | **same structure**; only the FAB set changes by platform | `kIsWeb` (platform, not width) | `video/.../video_view.dart:28,46,67` |
| 71 | Share map (guest) | Media | `ShareGuestScaffoldWidget` — 44.r top bar + content + 44.r footer | same, **no width cap** ⚠ | none (share mode is orthogonal to width) | `share/.../share_guest_scaffold_widget.dart` |
| 72 | Share history (guest) | Media | reuses `MapHistoryView` | reuses the landscape map | inherits | `app_pages.dart:505-510` |
| 73 | Share dialog | Dialog | `showModalBottomSheet`, top radius `16.r`, `maxWidth 696.r`, `maxHeight 600.r` | `showAdaptiveDialog` + `Dialog(insetPadding 16/24.r)`, radius 16 | `context.isAppPortrait` | `share/.../share_vehicle_dialog.dart:20`, `build_share_dialog_card_widget.dart:83-101` |
| 74 | Location picker (dialog) | Map picker | map `maxHeight = height*0.60`; **no editable lat/lng fields** | map `maxHeight = height*0.75`; editable lat/lng fields appear; address inline in the label row | `isAppLandscape` | `location/.../location_picker_view.dart:77`, `build_map_widget.dart:30,123` |
| 75 | Navigation | Utility | **stub** — `build => Container()` | stub | — | `location/navigation/.../navigation_view.dart:5-7` |
| 76 | Complete job (modal) | Utility | `SliverWoltModalSheetPage` | same | none | `jobs/.../complete_job_view.dart` |
| 77 | Custom command (dialog) | Form | single text field + button | same | none | `vehicles/.../custom_commands/build_custom_command_widget.dart` |
| 78 | Vehicle main commands | List | hardcoded 2×2 `Column`/`Row`, spacing `8.r` | **same 2×2**, only spacing → `16.r` ⚠ | `isAppLandscape` | `vehicles/.../shared/commands/build_main_command_widget.dart:133-155` |
| 79 | Event alerts filter sheet | Filter | `CustomModal.showPageModal` | `Overlay` popup anchored to the button | `isAppLandscape` | `events/.../filter/` + 6 sibling controllers |
| 80 | Settings pickers / tiles | Settings | `SettingsTile` row + modal sheet | `AccountSettingRow` with label column `width*0.35` + `ConstrainedBox(maxWidth: 520.r)` control | `isAppLandscape` (inside each tile) | `settings/.../map/*_settings_tile.dart`, `common/account_setting_row.dart:88,129-140` |

### C.6 Screens with **no** adaptive layout — [CODE]

Explicitly enumerated so they are not missed:

| Screen | Why it is acceptable | Why it is a risk |
|---|---|---|
| Splash, Onboarding, Update | Centred single-column content; nothing to rearrange | Animation height uses `context.height` only |
| Report details | The content is a fluid `WebView` | — |
| Profile | Only 3 cards | Stretches edge-to-edge on a 1920 px window with no readable-width cap |
| Video | Full-bleed `WebView` is the correct presentation | — |
| Share map / history | Full-bleed map is the correct presentation | — |
| Checkpoint create / edit (modal) | Sheet sizing owned by the modal layer | Map gets *smaller* in landscape |
| Commands (`lib/app/commands/`) | Data layer only — no UI | — |
| **Vehicle group create / edit** | — | **Real gap: single column stretched across 1440 px** |
| **Profile** | — | **Real gap: no max width** |

---

## D. Reusable pattern catalog

Nine patterns actually exist in the reference app. Nothing else was invented.

---

### Pattern 1 — Tabbed / filtered index with a table↔grid toggle

**When used.** Every index screen that lists domain records: vehicles, places, events, alerts,
event rules, alert rules, reports, waste containers, bus routes, vehicle groups, drivers,
trips, jobs, maintenances, event triggers, vehicle integrations.

**Narrow structure.** `CustomScaffold` → `Column` / `CustomScrollView` containing
(1) an optional scrollable tab strip or filter chips, (2) a `SearchFilterBar` (full width),
(3) a `ResponsivePagedSliverView` that renders a `ListView` when `crossAxisCount <= 1` and an
`AlignedGridView.count` otherwise, (4) a bottom padding of `mediaQuery.padding.bottom + 72..88.r`
to clear the FAB.

**Wide structure.** A shared base view provides the page:
- `ContentTabbedLandscapeViewPage<S>` (`view/content_tabbed_page_view.dart`) when the screen
  has tabs, or
- `GenericPagedView<T>` (`view/generic_paged_landscape_view.dart`) when it does not.

Both emit a single `CustomScrollView` with: `16.r` top spacer → optional `topWidget` →
header row → optional fixed spacer → `Expanded`-equivalent body (table **or** grid via
`SliverAnimatedSwitcher`) → `8.r + mediaQuery.padding.bottom` bottom spacer.

**Exact switching condition.**

```dart
// index (portrait)                             // index (landscape)
return context.isAppLandscape                  return context.isAppLandscape
  ? _buildLandscape(context)                     ? _buildLandscape(context)
  : _buildPortrait(context);                     : _buildPortrait(context);
```

The *column count* is a second, independent decision:

```dart
// lib/core/ui/widgets/custom_sliver_pagination_list.dart:53-64
int _getCrossAxisCount(BuildContext context) {
  final map = responsiveCrossAxisCounts ?? {1400: 3, 840: 2, 0: 1};
  final width = MediaQuery.of(context).size.width;   // ⚠ window width
  final sorted = map.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final bp in sorted) { if (width >= bp) return map[bp]!; }
  return 1;
}
```

**What moves / resizes / hides.**

| Element | Portrait | Landscape |
|---|---|---|
| Create action | `floatingActionButton: FloatingActionButton.extended(...)` in the app bar region | `endActionButton: CustomElevatedButton` **in the page header** |
| View-mode control | `CustomGirdListSwitch` in `actions` (gated by width inconsistently) | `ViewToggle` in the header (never gated) |
| Search | full-width `SearchFilterBar` | capped at `260.r` / `300.r`, right-aligned |
| Filter | `SearchFilterBar.onFilterTap` → `CustomModal.showPageModal` | `CustomFilterIconButton` → anchored `Overlay` popup |
| Tabs | `AppScrollableTabBar` / `ToggleSwitch` on its own row | `ContentTabbedPageTabsToggle` inside the header |
| Content | list or grid | table (default) or grid |
| Logo in app bar | shown | hidden when actions exist (`custom_app_bar.dart:106`) |

**Width constraints, spacing, proportions.**
- Header: `Padding(EdgeInsetsDirectional.only(start: 16.r, end: headerEndPadding))`, `Row(spacing: 8.r)`.
- `headerEndPadding` default: `16.r` when there is no `endActionButton`, else `0` (`generic_paged_landscape_view.dart:185`).
- `verticalSpaceBetweenHeaderAndContent`: `10.r` (list screens) or `16.r` (events/places).
- Table margin: `16.0.r` all round (`simple_vehicles_view.dart`); or `EdgeInsets.symmetric(horizontal: 16)` for `CustomPagingTableView`.
- Grid spacing: `16.r` main and cross for cards; `8.r`/`16.r` for waste.
- Table rows: `dataRowHeight: 64.0`, `headingRowHeight: 48.0`, `columnSpacing: 12.0`, `horizontalMargin: 24.0`
  (`table/custom_paginated_table_view.dart`).
- Table height: legacy `ContentLandscapeViewPage` hard-codes `SizedBox(height: context.height * 0.8)`
  (`content_landscape_page_view.dart:211`) — **a full-window fraction, a known weakness**.
  `GenericPagedView` instead lets the sliver fill remaining space and pins a pagination footer.

**Scrolling.** One `CustomScrollView` owns the page in landscape; the body sliver scrolls
independently of the sticky header. In portrait, the `ResponsivePagedSliverView` is a sliver
inside the same `CustomScrollView`, so header + list scroll together. `AlwaysScrollableScrollPhysics`
is used when `useScaffold` so pull-to-refresh works on a short list.

**Actions.** Always: create/primary on the trailing edge. Portrait → FAB (thumb-reachable);
landscape → inline button in the page header. Selection/bulk actions (`_SelectedCountButton`)
exist **only** in landscape (e.g. maintenances, event triggers, waste).

**States.** `RxDataStateWidget(rxData: controller.xState, onRetryClicked: controller.refreshX)`
wraps the whole body. Empty/error inside the paged list defaults to
`SizedBox(height: context.height * .4, child: EmptyDataWidget(...))` with `CustomLoading` for
the first page. `EmptyDataWidget` itself branches to a horizontal (animation | text) layout when
`context.isLandscape && isMobile`, and switches its message from `16.sp` to `20.sp` at 720 px.

**References.**
`view/content_tabbed_page_view.dart` · `view/generic_paged_landscape_view.dart` ·
`view/widgets/content_tabbed_page_header.dart` · `view/widgets/content_tabbed_page_tabs_toggle.dart` ·
`widgets/custom_sliver_pagination_list.dart` · `widgets/view_toggle.dart` ·
`widgets/table/custom_paginated_table_view.dart` · `widgets/components/custom_filter_icon_button.dart`

**Structural pseudocode (domain-neutral).**

```dart
// ── the shared wide view ─────────────────────────────────────────────
class WideIndexView<T, S> extends StatelessWidget {
  final BasePagedController<T> controller;
  final List<S> tabs;  // may be empty
  @override
  Widget build(BuildContext context) => CustomScaffold(
    title: controller.title,
    breadcrumbs: controller.breadcrumbs,          // auto-shown in wide
    child: RefreshIndicator.adaptive(
      onRefresh: controller.refreshData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 16.r)),
          HeaderRow(                                    // title | search | filter | toggle | CTA
            searchMaxWidth: 260.r,
            onViewModeChanged: (v) => controller.isTableView.value = v,
            endAction: CreateButton(onPressed: controller.create),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.r)),
          Obx(() => SliverAnimatedSwitcher(
            duration: 300.ms,
            child: controller.isTableView.value
                ? DataTable2Sliver(columns: cols, rows: rows)   // fixed header, scrolling rows
                : PagedGridSliver(
                    crossAxisCount: columnsForWidth(context.width), // {1400:3, 840:2, 0:1}
                    itemBuilder: (c, item, i) => RecordCard(item: item),
                  ),
          )),
          SliverToBoxAdapter(child: SizedBox(height: 8.r + context.mediaQuery.padding.bottom)),
        ],
      ),
    ),
  );
}

// ── the screen ──────────────────────────────────────────────────────
Widget build(BuildContext context) => context.isAppLandscape
    ? WideIndexView<Record, RecordTab>(controller: Get.find())
    : NarrowIndexView(controller: Get.find());   // Scaffold + FAB + SearchFilterBar + paged sliver
```

---

### Pattern 2 — `CustomOrientationWidget` split

**When used.** Details screens (12 of them), form shells, dashboard, settings host, map surface.
This is the *structural* counterpart to Pattern 1's shared base views.

**Structure.** An abstract widget with two required builders:

```dart
// lib/core/ui/widgets/custom_orienation_widget.dart
abstract class CustomOrientationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final child = context.isAppLandscape ? buildLandscape(context) : buildPortrait(context);
    return buildWidget(context, child) ?? child;   // optional wrapper override
  }
  Widget? buildWidget(BuildContext context, Widget child) => null;
  Widget buildPortrait(BuildContext context);
  Widget buildLandscape(BuildContext context);
}
```

**Variants observed.**
- **(a) Separate files.** `PortraitXView` / `LandscapeXView` classes in a `views/components/`
  folder. Used by the whole events family (alerts, event rules, alert rules) and vehicle details.
  *Benefit:* each orientation file stays short; *cost:* shared code duplicates.
- **(b) Single file, two methods, one body method with an `isLandscape` parameter.**
  `JobDetailsView`, `DriverDetailsView`, `MaintenanceDetailsView`, `TripDetailsView`,
  `BusRouteDetailsView`, `WasteContainerDetailsView` all do
  `buildPortrait => _buildPage(context, false); buildLandscape => _buildPage(context, true);`
  and thread `isLandscape` down. *This is the most reusable shape in the app.*

**What moves / resizes / hides** (the standard details transformation, [CODE]):

| Portrait | Landscape |
|---|---|
| `DefaultTabController` + `AppScrollableTabBar` + `TabBarView` | Tabs removed; sections stacked in a single scroll |
| one column, `Expanded` full width | 2 or 3 `Expanded` columns with a `16.r` gap |
| header padding `EdgeInsets.zero` / `12.r` | header padding `EdgeInsets.all(16)` |
| icon `40.r`, title `16.sp` | icon `64.r`, title `24.sp` |
| app-bar actions + FAB | actions move into the header card; FAB removed |
| tab bar may be `SliverPersistentHeader` pinned (`min = max = 47.5.r`) | pinning dropped |

**Width constraints.** The house two-column rule is literally:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,   // or .stretch inside IntrinsicHeight
  children: [
    Expanded(child: PrimarySection()),
    SizedBox(width: 16.r),
    Expanded(child: SecondarySection()),
  ],
)
```

Variants: `Expanded(flex: 3)` / `Expanded(flex: 2)` (trip details, 60/40);
`Expanded(flex: 1004)` / `Expanded(flex: 340)` (vehicle details, ~75/25);
`Expanded` + `SizedBox(width: 340.r)` (maintenance details, fixed secondary column).

**Scrolling.** Landscape = one `CustomScrollView` / `ListView(shrinkWrap)` inside the
`NestedScrollView` body. Portrait = `NestedScrollView` header sliver + `TabBarView` whose
children are `CustomScrollView(shrinkWrap: true)` — a genuine nested-scroll arrangement that
works because the inner views shrink-wrap.

**Actions.** The invariant is `floatingActionButton: isLandscape ? null : …` plus
`actions: isLandscape ? null : […]`. ⚠ In **jobs, driver and rehla** there is no landscape
replacement, so the action becomes unreachable in wide mode.

**States.** `RxDataStateWidget(state, onSuccess:, onRetryClicked:)` wrapping the body, with
`RefreshIndicator.adaptive` inside `onSuccess` in several screens (vehicle details both
orientations, driver details, rehla, ujrah).

**References.**
`widgets/custom_orienation_widget.dart` · the 12 `*DetailsView` files in §C.3

**Structural pseudocode.**

```dart
class RecordDetailsView extends CustomOrientationWidget {
  @override
  Widget buildPortrait(BuildContext c) => _buildPage(c, isLandscape: false);
  @override
  Widget buildLandscape(BuildContext c) => _buildPage(c, isLandscape: true);

  Widget _buildPage(BuildContext c, {required bool isLandscape}) => CustomScaffold(
    title: state.item.name,
    leading: AppBarLeadingType.back,
    breadcrumbs: [ /* shown automatically in wide */ ],
    actions:       isLandscape ? null : [EditButton()],
    floatingActionButton: isLandscape ? null : Fab.extended(label: primaryAction),
    child: RxDataStateWidget(
      rxData: state.itemState,
      onRetryClicked: controller.reload,
      onSuccess: (item) => isLandscape
          ? WideBody(item)   // Row of Expanded sections, 16.r gap
          : NarrowBody(item),// TabBar + TabBarView
    ),
  );
}
```

---

### Pattern 3 — Side-panel layout (sidebar + content card)

**When used.** Wide settings, and every wide multi-step form (job, report, maintenance create/edit).

**Structure** (`lib/core/ui/widgets/view/side_panel_layout_view.dart`):

```
CustomScaffold
└─ Column
   ├─ 16.hBox
   ├─ Expanded
   │  └─ Padding(horizontal 12.0, vertical 4)
   │     └─ IntrinsicHeight
   │        └─ Row(crossAxisAlignment: .start, spacing: 16.r)
   │           ├─ sidebarBuilder!(ctx, selected, items)   // or _DefaultSidebar
   │           └─ Expanded( _ContentArea )                 // animated card
   └─ (16.0 + mediaQuery.padding.bottom).hBox
```

**Default sidebar.** `Container(width: context.width * .15, padding: vertical 20.0)` holding
animated `InkWell` rows; the selected row is a `9999` pill in the brand colour, the rest are
`8.r`-radius, staggered in with `fadeIn` + `slideX` at `60 ms * index`.

**Form sidebar override.** Steps render a vertical stepper at
`min(240.r, context.width * .14)` (jobs, reports, maintenance create) or `context.width * .17`
(maintenance edit).

**Content area.** `AnimatedSize` (500 ms `easeInOutCubic`) wrapping an `AnimatedSwitcher`
(500 ms, fade + `Offset(0, 0.02)` slide + `ScaleTransition 0.98 → 1.0`, `alignment: topCenter`),
child = `Card(margin: EdgeInsetsDirectional.only(end: 24.r), color: cardBackgroundColor,
shape: RoundedRectangleBorder(side: cardBorderColor, borderRadius: 16.r))` with inner
`padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 16.r)`.

**Switching condition.** The *page* switches on `isAppLandscape`; `SidePanelLayoutView` itself
is only used on the wide branch, so it has no internal breakpoint.

**Scrolling.** The caller owns it: the form pages put an `Expanded(PageView)` (one page per step)
in the content area. `IntrinsicHeight` at the row level is a **cost risk** (§5.5).

**Actions.** Form pages: portrait puts them in a bottom row; landscape relies on per-step
buttons, or (alert/event rules) drops `stickyActions` entirely.

**States.** Maintenance edit wraps *both* orientations in `RxDataStateWidget(controller.maintenanceState)`.

**Structural pseudocode.**

```dart
WideWizardView(
  title: 'Create thing',
  breadcrumbs: [...],
  items: steps,                                   // e.g. [basicInfo, schedule, actions]
  selectedItem: controller.currentStep,           // Rx<Step>
  sidebarBuilder: (ctx, selected, all) => VerticalStepper(steps: all, current: selected),
  contentBuilder: (ctx, step) => Expanded(
    child: PageView(controller: pageController, children: stepPages(step)),
  ),
)
```

---

### Pattern 4 — Map + adjacent content (bottom sheet → side panel)

**When used.** Main map, trip map, waste map, map history, places group details, location picker,
vehicle/trip details map tab.

**Narrow structure — `SlidingUpPanel` over a full-bleed map.**

```dart
// lib/app/map/ui/map/views/shared/map_surface_widget.dart:69-93
SlidingUpPanel(
  maxHeight: isKeyboardVisible
      ? context.height * 0.36
      : context.height * dimens.mapInfoHeightFactor,   // .49 mobile / .52 tablet / .56 small mobile
  minHeight: context.height * 0.23,                    // .29 when there is no panelChild
  panelBorderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
  dragHandle: width: context.width * 0.14, height: 5.r, margin: top 8.r,
  ...
)
```

The map fills the screen; the panel is the only scrollable content.
History uses the same shape with `maxHeight = height*0.52`, `minHeight = 0`, `OPEN` default and
`allowFullyPanelClosingBehaviour: true`.

**Wide structure — `Stack[map, controls, Row[left card, right column]]`** inside a
`ClipRRect(16.r)` container, with widths from an explicit ladder:

```dart
// map_surface_widget.dart:173-213
final isPanelOnly      = config.supportsPanelOnly && width < 1200;
if      (width >= 1200 && width < 1450) { panel = w*0.28; info = w*0.30; pad =  8; }
else if (width >= 1450 && width < 1700) { panel = w*0.24; info = w*0.28; pad = 10; }
else if (width >= 1700)                  { panel = w*0.22; info = w*0.26; pad = 12; }
else { panel = width<600 ? w*0.35 : w*0.40; info = w*0.30; pad = 8; }
```

When `isPanelOnly` is true the info card is **not rendered at all** and the panel is the single
information host; `BuildPanelBody` then `AnimatedSwitcher`s between list and info inside the panel
(`build_panel_body.dart:13,21`).

**Switching condition.** `isAppLandscape` via `CustomOrientationWidget`; the *widths* use the
local 1200/1450/1700 ladder.

**What moves / hides.** Drag handle disappears. Map controls collapse from two corner clusters
(bottomStart + bottomEnd) to a single `bottomEnd` column (`build_shared_map_controls.dart:29-50`).
The street-view card inset changes from `end: 48.0` to `end: 92.r`. All controls hide while the
keyboard is visible. Camera padding is recalculated per mode
(`map_manager.dart:81-92`: `horizontalPercent = isLandscape ? (ar .3 : .6) : null`).

**Scroll ownership.** The panel owns the scroll (`WebScrollBlocker` + `PointerInterceptor` prevent
accidental page scroll on web). The map never scrolls.

**Actions.** Portrait: floating controls over the map. Landscape: controls pinned to the panel
edge — history uses `start: 4.r` normally and `start: 12.r + panelWidth` when the info card is
open, so controls shift to clear it (`build_map_with_panel.dart:237`).

**States.** `AnimatedVisibility(isVisible:)` toggles the whole surface; the host injects a
`DataStateWidget` as `panelChild`.

**Structural pseudocode.**

```dart
// narrow
SlidingUpPanel(
  maxHeight: h * 0.5, minHeight: h * 0.23,
  panel: InfoList(),          // the only scroll view
  body: Stack([MapView(), ...floatingControls]),
)

// wide
Stack([
  MapView(),
  ...rightAlignedControls,
  Row([
    SizedBox(width: w * 0.28, child: InfoList()),     // list column
    Expanded(child: InfoCard()),                      // or hidden when width < 1200
  ]),
])
```

---

### Pattern 5 — Dashboard (stat row + 2-column content)

**When used.** Home dashboard only.

**Narrow.** `CustomScrollView(padding: 12.r)` stacking: expiring banner → stats → rating → events → fleet chart.
FAB = `SpeedDial` (`DashboardActionsDialUp`).

**Wide.** `RefreshIndicator.adaptive` **wrapping** `Padding(16.r)` (inverted vs portrait) with:
- `Row[Expanded(actions card), Expanded(rating card)]`
- `Row[Expanded(flex 3)(events, height = context.height * 0.65), SizedBox(12.r), Expanded(flex 2)(fleet chart)]`
- bottom `80.r + mediaQuery.padding.bottom`

**Switching condition.** `isAppLandscape` for structure, `context.isWebLayout` for FAB suppression
⚠ (two different flags in one file).

**Stat card grid — a self-contained responsive widget.**
`dashboard/.../dashboard_stats_cards_section.dart` uses its own `LayoutBuilder` and listens to the
drawer controller to compensate for the rail:

```dart
final availableWidth = value.visible ? constraints.maxWidth * 0.75 : constraints.maxWidth;
final count = availableWidth < 340 ? 1 : availableWidth < 980 ? 2 : 5;
final iconSize = min(max(min(width, height) * 0.075, 40.r), 56.r);
```

This is a **good pattern** (it measures the *actual available box* rather than the window)
but the `* 0.75` drawer factor is a hard-coded assumption that breaks when the rail is expanded.

**Actions grid.** `dashboard_actions_dial_up.dart:199-201`:
`context.isAppLandscape ? 3 : (constraints.maxWidth > 600 ? 2 : 1)`, `mainAxisExtent: 72.r`,
spacing `16.r`. Note it reads `PlayxNavigation.navigationContext?.isAppLandscape` for
feature gating (line 75) — a stale-on-resize risk.

**Chart sizing.** Donut: portrait `size = min(w, h*0.9)`, `pieRadius = size/12` (min `60.r`);
landscape `size = (min(w,h)*0.8).clamp(180.r, 500.r)`, `centerSpaceRadius = outer*0.45`.
Line chart: landscape `(constraints.maxHeight * 0.64).clamp(180.r, 300.r)`, portrait `height*0.3`.

**References.**
`dashboard/.../dashboard_view.dart` · `dashboard_stats_cards_section.dart` · `chart_card.dart` ·
`event_card.dart` · `common/event_item_widget.dart` · `expiring_vehicles_banner.dart`

---

### Pattern 6 — Auth / centred card with optional side panel

**When used.** Login, forgot password (3 steps), update, onboarding.

**Narrow.** `BackgroundWidget` + a single centred card, `Column(crossAxisAlignment: .center)`.

**Wide.** The login screen is the reference example:

```dart
// lib/app/base/auth/ui/login/views/login_view.dart:44-105
SafeArea(
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 80.r),
    child: CustomScrollView(slivers: [
      SliverFillRemaining(child: Container(
        padding: EdgeInsetsDirectional.all(context.width < 720 ? 40.0.r : 12.0.r),
        child: Column(children: [
          Expanded(child: Container(
            margin: EdgeInsets.symmetric(vertical: 32.r),
            child: Center(child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1480.r),     // ← the readable-width cap
              child: Row(children: [
                if (showLoginFirst) Flexible(flex: showOnboarding ? 10 : 8,
                    child: _buildLandscapeLoginPane()),
                if (showOnboarding) ...[
                  SizedBox(width: 24.r),
                  const Flexible(flex: 10, child: LoginOnboardingView()),
                ],
                if (!showLoginFirst) Flexible(flex: showOnboarding ? 10 : 8,
                    child: _buildLandscapeLoginPane()),
              ]),
            )),
          )),
          _buildFooter(context),
        ]),
      )),
    ]),
  ),
)
```

The login pane is `ClipRRect(24.r)` + `Container(padding: start/end 56.r, top 48.r, bottom 32.r)`
with a two-layer shadow, and internally switches `crossAxisAlignment` to `.start` and swaps the
header `Row(HeaderBar(size: 150×52), actions)` in.

**Step preservation.** `PageStorageKey('forgetPasswordPageView')` keeps the current step across
the multi-step `PageView`; the outer `SafeArea`/`Center`/`HeaderBar` live in the host so they do
not flicker between steps.

⚠ The background `BackgroundWidget` is keyed on orientation
(`ValueKey('login-bg-${ctx.isDarkMode}-${ctx.isAppLandscape}')`, `login_view.dart:16`) — a
deliberate full-subtree rebuild on resize.

---

### Pattern 7 — Bottom sheet ↔ anchored popup for filters

**When used.** Every filter surface in the app — jobs, maintenances, waste, trips, bus routes,
events, alerts, event rules, alert rules.

**Switching condition (identical in 7 controllers) — [CODE]:**

```dart
if (context.isAppLandscape) {
  showFilterPopup(context, ...);      // OverlayEntry anchored to the trigger button
} else {
  await CustomModal.showPageModal(context, ...);   // full-height sheet
}
```

**Popup geometry** (`build_jobs_filter_widget.dart:66-86`) — the pattern to copy:

```dart
final popupWidth  = (screenSize.width * .5).clampedR.clamp(480.clampedR, width - 32.r);
final popupHeight = (screenSize.height * .33).clampedR.clamp(340.clampedR, height - 32.r);
final gap = 8.r;
```

This is genuinely good: it caps both ends, so the popup is readable on a 1920 px display and
still fits a 900 px window.

**No side-panel filters exist anywhere in the app.** That is a notable absence — a persistent
filter rail would be the natural wide-layout treatment.

---

### Pattern 8 — FAB ↔ inline header action

**When used.** All create/index/detail screens.

**Rule — [CODE]:**

```dart
// portrait
floatingActionButton: FloatingActionButton.extended(label: const Text('Create'), ...),
actions: [ /* icon buttons */ ],

// landscape
floatingActionButton: null,
endActionButton: CustomElevatedButton(label: Text('Create')),   // in the page header
actions: null,                                                   // breadcrumbs instead
```

`CustomElevatedButton` house metrics in headers: `minWidth: 80.r`, `minHeight/maxHeight: 40.r`,
`borderRadius: 12`.

`PlacesView` shows a third variant: a `FloatingActionButton.extended` rendered **inline inside the
header** with `elevation: 0`, `shape: radius 12`, wrapped in `Container(maxHeight: 44.r)`
(`places_view.dart:173-193`) — a FAB cosplaying as a header button.

⚠ Where the landscape branch supplies **no** replacement, the action is simply lost. This happens
in job details, driver details and bus-route details.

---

### Pattern 9 — Responsive empty / error state

**When used.** `EmptyDataWidget`, `ErrorWidget` — reached from every paged list, every
`RxDataStateWidget`, the map panels, tab bodies.

**Structure — [CODE]:**

```dart
// lib/core/ui/widgets/state/empty_data_widget.dart:30
return context.isLandscape && isMobile ? buildLandscape(context) : buildPortrait(context);
```

- `buildLandscape` = `Row(mainAxisSize: .min)[Expanded(animation, maxHeight: animationHeight ?? height*0.25), SizedBox(6.r), Expanded(text + optional retry)]`
- `buildPortrait` = `Column[animation, text, optional subtitle, retry]`
- Message font: `context.width < 720 ? 16.sp : 20.sp` — the single most-reused width rule in the
  codebase (14 occurrences), and the only one applied consistently across the whole app.

Heights: most callers use `context.height * .4` (lists) or `.25`/`.2` (details cards, tabs).
`animationHeight` is usually supplied explicitly, commonly `context.height * 0.2`.

**This is a pattern worth copying directly**, including the `min(animationHeight, height*0.25)`
guard so a tall animation never pushes the message off-screen in a short window.

---

## E. Shared adaptive components and their responsibilities

| Component | File | Responsibility | Responsive behaviour |
|---|---|---|---|
| `ResponsiveConfig` | `core/ui/widgets/responsive/responsive_config.dart` | All breakpoint constants, design sizes, animation defaults | — |
| `ResponsiveExtension` on `BuildContext` | same file | `isAppLandscape` (the switch), `isAppPortrait`, `deviceType()`, `isMobile/isTablet/isDesktop`, `valueWhen()`, `valueWhenWeb()`, `getDefaultPadding/Margin/Radius/Gap/IconSize`, `getResponsiveWidth`, `currentDesignSize`, `isWebLayout` | Defines everything |
| `ResponsiveNumExtension.clampedR` | same file | `.r` capped at 1.1× | Anti-ultra-wide guard |
| `PortraitConstraint` | `responsive/portrait_constraint.dart` | `Center + ConstrainedBox(maxWidth: 600)` outside landscape | **Wired but never enabled** |
| `CustomScaffold` | `core/ui/widgets/components/custom_scaffold.dart` | `SafeArea` + app bar + `Scaffold` + `PopScope`; `attachPortraitConstraint`, `isInitialized` (shows `CenterLoading.adaptive` until first frame), `includeBottomSafeArea` | RTL-aware safe area: `right: isPortrait \|\| isLtr`, `left: isPortrait \|\| isRtl` |
| `buildAppBar` | `core/ui/widgets/components/custom_app_bar.dart` | App bar chrome; `AppBarLeadingType` {none, back, drawer}; breadcrumbs; logo + support | Height `44.0` (wide) vs `kToolbarHeight`; breadcrumbs shown when `attachBreadcrumb ?? isAppLandscape`; logo hidden on web or when actions exist |
| `BreadcrumbHeader` | same file | Collapses >4 crumbs to `first … last3`, horizontally scrollable | Wide-only by default |
| `CustomPageScaffold` | `core/ui/widgets/components/custom_page.dart` | Wraps a `StatefulNavigationShell` in `CustomDrawer`; skips chrome in `ShareSession` mode | — |
| `CustomDrawer` + `AdvancedCustomDrawer` | `app/base/app/.../drawer/` | Rail vs overlay drawer | See §F/§shell below |
| `DrawerScale` | `drawer/layout/drawer_layout_scale.dart` | `r()` / `sp()` → raw dp in landscape, `.r`/`.sp` in portrait | The canonical "freeze scaling in wide" helper |
| `ContentTabbedLandscapeViewPage` | `core/ui/widgets/view/content_tabbed_page_view.dart` | Tabbed wide index; `TogglePosition` {afterTitle, afterSearch, end, belowHeader} | `TabBarView(physics: NeverScrollableScrollPhysics)` |
| `ContentTabbedPageHeader` | `.../widgets/content_tabbed_page_header.dart` | Header with title/toggle/search/filter/actions | **Collapses to two stacked rows below `width < 1100`** |
| `GenericPagedView` | `core/ui/widgets/view/generic_paged_landscape_view.dart` | Non-tabbed wide index + pagination footer | `AlwaysScrollableScrollPhysics` when `useScaffold` |
| `ContentLandscapeViewPage` | `core/ui/widgets/view/content_landscape_page_view.dart` | Older, simpler wide index | Table height hard-coded to `height*0.8` ⚠ |
| `SidePanelLayoutView<T>` | `core/ui/widgets/view/side_panel_layout_view.dart` | Sidebar `width*.15` + animated content card | — |
| `ResponsivePagedSliverView` | `core/ui/widgets/widgets/custom_sliver_pagination_list.dart` | Paged list-or-grid sliver; `groupBy` support | `{1400:3, 840:2, 0:1}`; bottom inset `+72` |
| `context.crossAxisCount()` | `core/utils/extensions.dart:188` | Duplicate ladder helper | `{1400, 840}` |
| `CustomTableView` / `CustomPagingTableView` | `core/ui/widgets/table/` | `DataTable2` / `AsyncPaginatedDataTable2` wrappers | `LayoutBuilder` clamps table height to `min(contentHeight, maxHeight)`; **static columns — never reduced by width** |
| `ViewToggle` | `core/ui/widgets/view_toggle.dart` | Table ↔ grid switch, `FittedBox(scaleDown)`, 40.r tall | Always available on wide |
| `CustomSearch` | `core/ui/widgets/custom_search.dart` | iOS `CupertinoSearchTextField` / Material `CustomTextField` | `maxWidth` supplied by the host |
| `CustomResponsiveCard` | `responsive/widgets/custom_responsive_card.dart` | Card with hover states | Shadow blur/offset from a `DeviceType` switch (mobile 8/12, tablet 12/16, desktop 16/20); `MouseRegion` + `SystemMouseCursors.click`; `expand` flag uses `LayoutBuilder` for bounded height |
| `CustomResponsiveBuilder` | `responsive/widgets/custom_responsive_builder.dart` | mobile/tablet/desktop builders + 200 ms web-resize debounce | **Unused** |
| `AnimatedWidgetWrapper` / `StaggeredAnimationWrapper` | same folder | Fade/slide/scale-in, staggered by index | — |
| `EmptyDataWidget` / `ErrorWidget` | `core/ui/widgets/state/` | Shared empty/error | `isLandscape && isMobile` → row layout; 720 px font switch |
| `RxDataStateWidget` / `DataState` | `core/ui/ui/data_state/` | Sealed loading/success/empty/error/no-internet | `enableCheckingInternet` disabled on web in the dashboard |
| `LoadingOverlay` | `core/ui/widgets/state/loading_overlay.dart` | Global blocking overlay, mounted **inside the drawer stack** so it covers content but not the rail | — |
| `DetailItem` | `core/ui/widgets/components/detail_item.dart` | The **only** shared detail component that branches on orientation (font 13/14, icon 16/18) | Used in list rows, not in details screens |
| `DetailsInfoCard` / `DetailsInfoRow` / `DetailsHeaderSection` | `components/` | Bespoke detail building blocks | **No width branching**; used by 1–3 screens each |
| `WebBodySelectionArea` | `components/web_details_selection_area.dart` | Wraps content in `SelectionArea` on web only | Applied app-wide by `CustomScaffold`; the 4 "details" variants are dead code |
| `KeyboardVisibilityBuilder` | playx | Used by 6 screens to hide the action bar when the keyboard opens | See §5.2 |
| `BasePagedController<T>` | `core/ui/widgets/view/controller/` | `searchController`, `pagingController`, `isTableView`, `totalItemsCount`, `refreshData`, `updateSearch` | Seeds `isTableView = ScreenUtil().screenWidth > 900` ⚠ |
| `PaginatorController` + `PagedTablePaginationControls` | playx / local | Fixed pagination footer | Wide only |

---

## F. Application shell

### F.1 Navigation container — [CODE]

`CustomPageScaffold` (`core/ui/widgets/components/custom_page.dart:38-61`) renders
`PlatformScaffold(body: CustomDrawer(navigationShell, child))` for shell routes, and skips the
drawer entirely when `ShareSession.isActive`.

`CustomDrawer` (`app/base/app/.../drawer/custom_drawer.dart:20-33`):

```dart
final railCollapsedWidth = context.isAppLandscape
    ? 48.0
    : 72.0 + (context.isLtr ? context.mediaQueryPadding.left : context.mediaQueryPadding.right);
final railExpandedWidth  = context.isAppLandscape ? 237.0 : context.width * .75;

AdvancedCustomDrawer(
  breakpoint:   ResponsiveConfig.landscapeBreakpoint,   // 1080
  railMinWidth: railCollapsedWidth,
  railMaxWidth: railExpandedWidth,
  openRatio:    context.isAppLandscape ? .25 : .75,
  openScale:    context.isAppLandscape ? 1.0 : 0.85,
  childDecoration: BorderRadius.circular(context.isAppLandscape ? 16.0 : 16.r),
  rtlOpening:   PlayxLocalization.isCurrentLocaleArabic(),
  ...
)
```

`AdvancedCustomDrawer.build` (`drawer/layout/advanced_custom_drawer.dart:73-217`) branches on
`MediaQuery.size.width >= widget.breakpoint`:

| | Wide (rail) | Narrow (overlay drawer) |
|---|---|---|
| Layout | `Stack[backdrop, Row[AnimatedContainer(width: railMin/railMax), Expanded(child)], LoadingOverlay]` | `Stack[backdrop, FractionallySizedBox(widthFactor: openRatio, scale), SlideTransition+ScaleTransition(child), scrim]` |
| Gesture | none (toggle button only) | horizontal drag, disabled via `disabledGestures` |
| Animation | `AnimatedContainer` width, 300 ms `easeInOut` | slide `Offset(openRatio, 0)` + scale to `openScale`, child slides back by its own width |
| Safe area | `MediaQuery.removePadding(removeLeft: isAppLandscape && isLtr, removeRight: isAppLandscape && isRtl)` | handled by the drawer's own `SafeArea` |

**Navigation width and its effect on content width.** The rail is 48 px collapsed / 237 px
expanded in wide mode — so the *content box* is 48–237 px narrower than the window. Yet
essentially every content widget measures `context.width` (the **window**), not the content box.
This is the single largest structural weakness (§5.4). Only `DashboardStatsCardsSection`
compensates (multiplying by `0.75` when the drawer is visible).

`ResponsiveConfig.extendedRailWidth = 221` vs the `237` actually used in `CustomDrawer`, and
`ResponsiveConfig.railWidth = 72` vs the `72` re-declared as a `BuildContext` extension
(`responsive_config.dart:105-106`) — three sources of the same numbers.

### F.2 Drawer body — [CODE]

`CustomDrawerBody` (`drawer/body/drawer_body.dart`):
`SafeArea(left: isLtr, right: isRtl, bottom: false)` → `Column[logo section, Expanded(scrolling
items), Divider, SupportButton, user profile]`, and **only in portrait** the version footer +
`mediaQueryPadding.bottom` spacer. All sizes go through `DrawerScale.of(context)` so they freeze
at dp in wide mode. Items are `DrawerNavigationItemView`; in the collapsed rail a tap opens a
floating submenu beside the item (`DrawerCollapsedNavigationItem` →
`controller.openDrawerCollapsedItemMenu`). Section headers ("Main modules", "Active modules")
and labels are dropped in the collapsed state.

### F.3 App bar, headings, breadcrumbs — [CODE]

- Height `44.0` (wide) vs `kToolbarHeight` (narrow); `leadingWidth` `52.0` vs `40.0` on Android portrait.
- **Leading swaps to the menu button** in wide mode whenever breadcrumbs are shown
  (`AppBarLeadingType.back.buildWidget` returns `MenuIconButton` when `breadcrumbShown && !forceBack`,
  `custom_app_bar.dart:24-26`) — because the page is a drill-down, not a stack push.
- Breadcrumbs render by default **only in wide mode**: `includeBreadcrumb = (attachBreadcrumb ?? isLandscape) && breadcrumbs.isNotEmpty`
  (`custom_app_bar.dart:70`). Settings overrides this to `true` in both orientations.
- The logo + support button are hidden on web and when `actions != null`, so a landscape page
  with a header CTA does not carry redundant branding.
- The content page title lives **in the page**, not the app bar, on wide screens (the
  `ContentTabbedPageHeader` / `_GenericPagedHeader` first row).

### F.4 Persistent vs collapsible regions — [CODE]

| Region | Narrow | Wide |
|---|---|---|
| Navigation | Collapsible overlay drawer (`.75` of width) | Persistent rail, 48 px ↔ 237 px, animated width |
| Tabs (index screens) | On its own row, scrollable | Inside the page header, `ToggleSwitch(useNewStyle, isCompact)` |
| Table header + pagination | n/a | Fixed header and footer; only rows scroll |
| Tab bar (details) | Sticky `SliverPersistentHeader` (`min = max = 47.5.r`) or inline | Removed |
| Map info panel | `SlidingUpPanel`, draggable, resizable | Fixed-width card, not draggable |
| Breadcrumbs | Hidden | Always visible |

### F.5 Safe area and keyboard — [CODE]

- `CustomScaffold`: `SafeArea(bottom: includeBottomSafeArea, right: isPortrait || isLtr, left: isPortrait || isRtl)`.
  The left/right rules are direction-aware: in RTL the right inset is applied, in LTR the left.
- `AdvancedCustomDrawer` strips the *outer* insets in wide mode (`removeLeft/removeRight`) because
  the rail needs the full width; `CustomDrawerBody` re-applies them internally.
- Views add their own bottom padding: `8.r + mediaQuery.padding.bottom` (list screens),
  `12.r + padding.bottom` (dashboard/profile), `72..88.r + padding.bottom` where a FAB overlaps.
- **Keyboard:** 6 screens use `KeyboardVisibilityBuilder` to *hide* the action bar; only 4 files
  use `MediaQuery.viewInsets.bottom` (`vehicle_selection_modal_shell.dart:131`,
  `settings_modal.dart:43`, `change_password_dialog.dart:116`, `build_edit_report_schedule_body.dart:16`).

### F.6 RTL / LTR — [CODE]

- Drawer opens from the correct side: `rtlOpening: PlayxLocalization.isCurrentLocaleArabic()`,
  and `Align(alignment: rtlOpening ? centerRight : centerLeft)`.
- Menu button rotates `0.5` turns, direction-aware: `value.visible ? (isRtl ? 0 : .5) : (isRtl ? .5 : 0)`.
- Padding is mostly `EdgeInsetsDirectional` / `paddingOnly(start:)`, so it mirrors for free.
  ⚠ A minority of places use raw `EdgeInsets.symmetric(horizontal:)` or `left/right` (the whole
  drawer body, `Scaffold` margin in `SidePanelLayoutView._ContentArea` uses
  `EdgeInsetsDirectional.only(end: 24.r)` — correct — but `CustomTableView`'s `TableBorder` and
  several `SizedBox(width:)` are not direction-aware).
- FAB position follows locale: `FloatingActionButtonLocation.endFloat` (LTR) vs `startFloat` (RTL)
  in vehicle-group details (`group_details_view.dart:75-77`).
- Sliding panels animate from the correct side: `AnimatedSwitcher` uses `Offset(1,0)` in LTR and
  `Offset(-1,0)` in RTL (`places/.../group_details_view.dart`).
- `DrawerExpandedNavigationItem` / popup anchors use `Builder(anchorContext:)` for correct
  `showMenu` positioning in both directions.

### F.7 Pointer, hover, focus, keyboard — [CODE]

- **Hover:** `CustomResponsiveCard` implements a real hover state — `MouseRegion` with
  `SystemMouseCursors.click` when tappable, blending `primary @ 2 %` into the background and
  adding `+8` blur. `CustomTableView` resolves `dataRowColor` on `WidgetState.hovered`
  (primary @ 5 %) and `WidgetState.selected` (primary @ 10 %).
- **Web scroll:** `WebScrollBlocker` + `PointerInterceptor` around map panels and sheets
  (`map_surface_widget.dart:140-145`, `share_vehicle_dialog.dart:22-23`) prevent the page from
  scrolling while a map or sheet is open.
- **Web gestures:** `AdvancedCustomDrawer` disables horizontal drag when `disabledGestures` is set
  (set for the map branch and for routes in `NavigationUtils.disabledGesturesRoutes`).
- **Keyboard navigation:** not implemented. No `FocusTraversalGroup`, no `Shortcuts`/`Actions`,
  no visible focus rings. `AutofillGroup` is used on login. `PopScope` handles Android back and
  deliberately no-ops on web (`if (didPop || kIsWeb) return;`).
- **Text selection:** `WebBodySelectionArea` wraps every `CustomScaffold` body, so selection works
  on web everywhere.

### F.8 Resize handling — [CODE]

`CustomOrientationWidget` and every `Obx` rebuild on `MediaQuery` change automatically, so
resizing a browser window swaps layouts live. Two explicit accommodations exist:
`CustomResponsiveBuilder` (unused) debounces web resizes by 200 ms, and `DashboardStatsCardsSection`
subscribes to the drawer controller. The places marker/zone forms hoist a single
`ScrollController` into the parent `State` and pass it to both orientations
(`create_marker_view.dart:14,82-86`) — **the only place scroll position is explicitly preserved.**

---

## G. Exceptions, inconsistencies, and potential weaknesses

Ordered by how likely they are to be copied into a target app by accident.

### G.1 Structural weaknesses

| # | Issue | Evidence |
|---|---|---|
| 1 | **`maxPortraitWidth = 600` is dead.** `PortraitConstraint` is only reachable via `CustomScaffold(attachPortraitConstraint: true)` and **no call site sets it**. Portrait tablets and sub-1080 browser windows stretch the phone layout full-bleed. | `responsive_config.dart:26`; `portrait_constraint.dart`; `custom_scaffold.dart:53,142-143`; `responsive/widgets/portrait_constraint.dart` is a duplicate dead class |
| 2 | **Almost all content measures the window, not the content box.** `context.width` is used for column counts, panel widths, and even the settings label column, while a 48–237 px rail is subtracted. 42 width comparisons found; the overwhelming majority use `context.width`. | `custom_sliver_pagination_list.dart:56`; `account_setting_row.dart:88,135`; `settings_web_view.dart:36`; `build_map_info_responsive_pair.dart:21`; `dashboard_stats_cards_section.dart:54` |
| 3 | **The nav rail eats width but nothing accounts for it**, except the dashboard's hard-coded `* 0.75` (which assumes the rail is exactly 25 % — true only when expanded, false at 48 px collapsed). | `dashboard_stats_cards_section.dart:22-24` vs `custom_drawer.dart:20-23` |
| 4 | **No global readable-width cap.** Only login (`1480.r`), forgot password (`760.clampedR`), places group (`700.r`) and map pickers have one. Profile, report details, video, share guest pages and vehicle-group forms have none. | see §C.6 |
| 5 | **Table columns never change with width.** Every screen defines a fixed `columns` list; the only conditional column anywhere is vehicles' `hideStatus`. Wide-narrow horizontal scrolling is handled by `DataTable2`'s internal scroll. | `build_simple_vehicles_table.dart:29,45`; `custom_paginated_table_view.dart` |

### G.2 Inconsistencies that a copying agent will hit

| # | Issue | Evidence |
|---|---|---|
| 6 | **Two `isLandscape` concepts coexist.** `context.isAppLandscape` (1080 web / 840 native) is the layout switch. `context.isLandscape` (raw `MediaQuery.orientation`) is used ~20× for chrome, and `context.isWebLayout` is *provably identical* to `isLandscape` (`(isTablet \|\| isDesktop) && isLandscape \|\| isLandscape`) yet is used as a distinct guard. A 640–839 px phone in physical landscape therefore gets the **landscape tree with portrait chrome**. | `responsive_config.dart:335`; `dashboard_view.dart:24,110`; `event_card.dart:12`; `update_vehicle_icon_controller.dart:67` (`isAppLandscape \|\| isWebLayout` is redundant) |
| 7 | **The 900 px table seed** puts the app in portrait mode with table view selected for widths 900–1080. | `base_paged_controller.dart:37`; `places_controller.dart:38`; `waste_controller.dart:31` |
| 8 | **Grid ladders disagree inside the same screen.** Events and Event Rules use `{900:3, 600:2, 0:1}` in the wide branch and `{1400:3, 840:2, 0:1}` in the narrow branch — 3 columns at 900 px wide. | `events_view.dart:72` vs `:158,172`; `event_rules_view.dart:58` vs `:122,136` |
| 9 | **Four distinct 840-derived gates** with three different forms: `>= 840`, `< 840`, `> 840.0`, plus screens with no gate at all. | `jobs_view.dart:14`; `bus_routes_view.dart:29`; `places_view.dart:386`; `maintenances_view.dart:24` (unconditional); `ujrah` (none) |
| 10 | **Sidebar widths drift** between sibling screens: `min(240.r, width*.14)` (jobs/reports/maint-create) vs `width*.17` (maint-edit). Rotating a maintenance form resizes the sidebar by 21 %. | `job_form_shell.dart:81`; `create_maintenance_view.dart:66`; `edit_maintenance_view.dart:76` |
| 11 | **`stickyActions` is passed in portrait and dropped in landscape** for alert and event rules, so resizing moves the confirm bar from a fixed footer into the scroll content. | `alert_rule_form_shell.dart:37` vs `:52`; `event_rule_form_shell.dart` |
| 12 | **Search max width has 4 values** (260 / 300 / 300 / 308). | `content_tabbed_page_header.dart:64`; `content_landscape_page_view.dart:200`; `generic_paged_landscape_view.dart:72`; `content_tabbed_page_search_bar.dart:19` |
| 13 | **Gutters drift**: `16.r` (most), raw `16` (older details screens), raw `15` (Rehla). | `bus_route_details_view.dart:47,76-94` |
| 14 | **`Context.getDefaultPadding/getDefaultRadius/getIconSize/getResponsiveWidth` are essentially unused** in app code — the real system is `.r` literals and `isAppLandscape`. | `responsive_config.dart:226-293`; one use at `vehicle_groups_landscape_view.dart:42-49` |
| 15 | **Dead code that looks like the framework:** `CustomResponsiveBuilder`, `WebDetailsSelectionArea` + 3 siblings, `AdvancedVehiclesView` (`return const SizedBox.shrink()`), `responsive/widgets/portrait_constraint.dart` (duplicate class), `BuildMapToolbar.isVertical` (accepted, never read), `MapModuleTabBar` (deprecated typedef), `BuildSimpleVehiclesPortraitBody.crossAxisCount` (accepted, hardcoded to 2), `BuildReportsListWidget.getCrossAxisCount` (both branches return 2). | see each file |

### G.3 Confirmed defects that should not be copied

| # | Defect | Evidence |
|---|---|---|
| 16 | **Vehicle-group create/edit has no wide layout at all** — single column stretched across 1440 px — *and* uses `context.mediaQueryPadding.bottom` (safe area) instead of `viewInsets`, so the confirm bar sits under the keyboard. | `create_vehicle_group_view.dart:16-49`; `edit_vehicle_group_view.dart:16-47` |
| 17 | **Landscape action loss**: job details, driver details, bus-route details all null the FAB and app-bar actions with no wide replacement. | `jobs/.../details_view.dart:28-30`; `driver_details_view.dart:24-37`; `bus_route_details_view.dart:14,24-37` |
| 18 | **Places marker details use `width: context.width` inside `Expanded`** on three containers → overflow/clipping. | `landscape_marker_details_content.dart:29,102,122,260`; `portrait_marker_details_content.dart:20` |
| 19 | **Settings web sidebar sets `width: context.width` inside a `width*.15` container**; and the label column is `width*0.35` of the *screen* inside the panel, leaving ~300 px for a `520.r`-capped control at 1440 px. | `settings_web_view.dart:36`; `account_setting_row.dart:88,135`; `account_web_layout_section.dart:78` |
| 20 | **Rehla rest point is a fixed `1171.clampedR × 688.clampedR` card.** `clampedR` caps at 1.1× so on a 375 pt phone that is ~1288 px — guaranteed overflow. | `create_edit_rest_point_view.dart:16-17` |
| 21 | **Checkpoint modal map gets *smaller* in landscape** (`height*0.55` vs `height*0.8`). | `build_checkpoint_form_widget.dart:45` |
| 22 | **Waste edit landscape form is not scrollable** — direct child of `Expanded`. | `edit_waste_container_view.dart:69-79` |
| 23 | **Change-password uses an off-system condition** `isAppPortrait && !isTablet`, so a **portrait tablet gets a dialog** while a 640 px portrait phone gets a sheet. | `change_password_dialog.dart:12` |
| 24 | **`IntrinsicHeight` wraps expensive content twice**: around the side-panel `Row` (every wide form step) and around a `Row` containing a data table. | `side_panel_layout_view.dart:103`; `build_event_trigger_form_main_tab.dart:45` |
| 25 | **Bus routes renders search twice in portrait** — in the app bar *and* in a `SearchFilterBar` in the body. | `bus_routes_view.dart:16-34,50-55` |
| 26 | **Ujrah list has no landscape filter affordance** (`filterButton` commented out) although the controller still implements the popup branch. | `trips_view.dart:49-54`; `trips_controller.dart:73` |
| 27 | **Waste details shows fewer tabs in landscape** (2 of N) than portrait. | `waste_container_details_view.dart:118-121` |
| 28 | **Rehla bus-route details hides the operator card in portrait** but shows it in landscape (commented-out code). | `bus_route_details_view.dart:107` vs `:87` |
| 29 | **Navigation-context branching** (`PlayxNavigation.navigationContext?.isAppLandscape`) does not rebuild on resize. | `dashboard_actions_dial_up.dart:75`; `map_manager.dart:81` |
| 30 | **Duplicated panel-width ladder** between `build_map_with_panel.dart:55-61` and `build_map_with_controls.dart:196-202`. | — |

---

## H. Edge cases: confirmed behaviour vs risk

### H.1 Confirmed by code — [CODE]

| Case | Behaviour |
|---|---|
| **Short-height landscape** (e.g. 1280×600) | Content uses `Expanded` and `Flex` almost everywhere, so vertical compression is handled. Explicit height fractions: list empty state `height*0.4`, dashboard chart `height*0.65`, map panel `height*0.23..0.5`. Risk: `EmptyDataWidget`'s animation is clamped by `min(animationHeight, height*0.25)`. |
| **Narrow browser window (< 1080)** | Falls into the *portrait* layout entirely — correct decision, but that layout is not width-capped (§G.1.1) so it stretches. Between 900 and 1080 the table-view seed conflicts. |
| **Large tablet (portrait, ≥ 600)** | `deviceType() == tablet` → 768×1024 design canvas, `.r` scales ~2× vs phone. Landscape at 1024 pt falls **below** the 840 threshold? No — 1024 ≥ 840, so a 1024×768 iPad in landscape *does* get the wide layout. An 834×1194 iPad in landscape (834 pt) does **not**. |
| **Very wide desktop (2560 px)** | `.r` scales with the 1440 px canvas (~1.78×). `clampedR` caps structural values at 1.1×. Chrome uses raw dp. Grid goes to 3 columns and stops. No column 4, no wider table column set → the widest layout is the 1440 px one, centred implicitly by a full-bleed table. |
| **Orientation change / window resize** | Rebuilds and swaps trees via `isAppLandscape`. Form controllers are `TextEditingController`s owned by GetX controllers, so values survive. Only the places marker/zone forms explicitly preserve scroll offset. |
| **Tab state on resize** | Preserved when the tab index is an `Rx` on a GetX controller or a `PageStorageKey`. **Lost** when held by a `DefaultTabController` created inside the body (event triggers). |
| **Selection on resize** | No screen stores selection state outside a controller, so it survives. Web is the only place selection matters and rows are click targets. |
| **Long/translated text** | `TextOverflow.ellipsis` on page titles; `Expanded`/`Flexible` around most text; breadcrumbs collapse to 3 + `…`; `AppScrollableTabBar` scrolls. Arabic uses Cairo, English Poppins (`fontFamilyBasedOnText`). ⚠ Hard-coded flex ratios assume short labels. |
| **Dense lists** | Infinite scroll via `PagingController` + `PagedChildBuilderDelegate`; `CustomPagingTableView` has a `serverTotalRowCount` hook to avoid placeholder-spinner rows. |
| **Nested scrolling** | `NestedScrollView` + `TabBarView` with `shrinkWrap: true` inner scrolls (job, driver, maintenance, ujrah, rehla, vehicle-group details). Works because inner views shrink-wrap; costs a second layout pass. |
| **Keyboard on forms** | 6 screens hide the action bar via `KeyboardVisibilityBuilder`; 4 use `viewInsets`. ⚠ See §H.2. |

### H.2 Risks (not observed at runtime) — potential

| Risk | Why |
|---|---|
| **`clampedR` behaves surprisingly on narrow windows** | `clampedR = min(value.r, value * 1.1)`. On a window narrower than the design canvas, `value.r < value * 1.1`, so the cap never engages. On a *wider* window, `value.r > value * 1.1` and the result collapses to exactly `1.1 × value` — i.e. `clampedR` silently discards all screen-util scaling above 1.1× and becomes a constant. Used for structural sizes (`1171.clampedR`, `480.clampedR`) this may be intended, but it is surprising. |
| **Popup/modal clamping assumes window space, not parent space** | `(screenSize.width * .5).clamp(480, width - 32.r)` — if the trigger is inside a narrow panel, the popup can be wider than the space beside it. |
| **Forms with a fixed-width landscape body may overflow on short landscape** | Waste edit is not scrollable; maintenance edit's fixed `340.r` assets column plus `Expanded` overview is tight below ~700 px of height. |
| **Keyboard + landscape phone** | A phone at 840×400 that receives the wide layout with a form has very little height; only 4 forms read `viewInsets`. |
| **`IntrinsicHeight` in a scrolling context** | `SidePanelLayoutView` wraps the whole form row in `IntrinsicHeight`; combined with `Expanded` children and a `PageView` this is O(n) layout per frame and can jank on long forms. |
| **RTL + two-column rows with asymmetric content** | `Row` + `Expanded` mirrors correctly, but the *reading order* changes: an LTR `Row[primary, secondary]` becomes `Row[primary, secondary]` in RTL too (children keep order, layout direction flips) — this is usually what you want, but the reference app does not verify it anywhere. |
| **No keyboard focus traversal on web** | A 64-route app with zero `Shortcuts`/`Actions`/`FocusTraversalGroup` is not keyboard-operable. If the target app targets web, this is a gap to close, not to copy. |

---

## I. Practical procedure for adapting another application

**This section is entirely `[RECOMMENDED]`.**

### Step 0 — Do not start from the portrait code

The single highest-leverage move, learned from the reference app's dead `PortraitConstraint`:
**build the shell and the shared list/detail views first, in a breakpoint-agnostic form, and let
screens supply only their content builders.** The reference app's best ideas (`GenericPagedView`,
`ContentTabbedLandscapeViewPage`, `SidePanelLayoutView`, `CustomOrientationWidget`) are all
*structure*, not styling.

### Step 1 — Define the mode function and nothing else

```dart
// one extension, one getter, in the reference app's spirit but simpler
enum LayoutMode { compact, medium, expanded }

LayoutMode modeOf(double width, {required bool isWindowPlatform}) {
  if (isWindowPlatform) return width >= 1280 ? LayoutMode.expanded : LayoutMode.compact;
  return width >= 840 ? LayoutMode.expanded : LayoutMode.compact;   // 840 for native
}
```

Rules:
- **Never branch on `MediaQuery.orientation` alone.** It is unreliable in browser windows.
- **Pick two thresholds, not three.** 840 (native) and 1280 (desktop/window) is a defensible
  pair; 600/1080/1400 is not.
- **Keep `LayoutMode` orthogonal to `deviceType`.** Use `deviceType` only for *size* functions,
  never for structure. This avoids the reference app's `isWebLayout`-vs-`isAppLandscape` split.

### Step 2 — Build the shell

- Navigation rail for `expanded`, collapsible drawer for `compact`.
- **Publish the rail width** so content can subtract it. Prefer `LayoutBuilder`/`constraints.maxWidth`
  inside the content area; fall back to `MediaQuery.width - railWidth`.
- App bar: keep a fixed height in `expanded` (stop scaling chrome), `kToolbarHeight` in `compact`.
- Show breadcrumbs in `expanded`; hide them in `compact`.
- Keep the RTL/LTR safe-area logic the reference app uses
  (`right: isPortrait || isLtr`, `left: isPortrait || isRtl`).

### Step 3 — Give every screen a two-branch structure, by pattern

Classify each existing screen and pick the pattern from §D:

| Screen content | Pattern |
|---|---|
| A list of records | **P1** — paged list/grid ↔ table |
| A record's full detail | **P2** — tabs ↔ 2–3 columns |
| A wizard / multi-step form | **P3** — stepper + `PageView` ↔ side panel + `PageView` |
| A single-column form | P2 variant — centred `ConstrainedBox` ↔ 2 equal columns |
| A map with data | **P4** — `SlidingUpPanel` ↔ side card + info column |
| A dashboard | **P5** — stacked ↔ stat row + 2 columns |
| Auth / marketing | **P6** — centred card ↔ card + side panel, with a max width |
| Filters | **P7** — sheet ↔ anchored popup with clamped dimensions |
| Any create action | **P8** — FAB ↔ inline header button |

### Step 4 — Constrain by constraints, not by window

This is the reference app's biggest lesson. In every shared view, prefer:

```dart
LayoutBuilder(builder: (context, constraints) {
  final w = constraints.maxWidth;        // ✅ the box I actually own
  final columns = w >= 1200 ? 3 : w >= 700 ? 2 : 1;
  ...
})
```

Reserve `context.width` for cases where you genuinely mean the *window* (map camera padding,
full-bleed overlays, `SlidingUpPanel` max heights). If you must subtract the rail, expose
`contentWidth = MediaQuery.widthOf(context) - railWidth` once in the shell.

### Step 5 — Set an explicit content maximum width

Do not rely on `.r` to stop a 375 px card from stretching to 1920 px. Put it in the scaffold:

```dart
Widget build(BuildContext context) => modeOf(...) == LayoutMode.compact
    ? PortraitConstraint(maxWidth: 600, child: child)   // ← actually use it
    : child;
```

Pick one value (≈ 560–720 for forms, ≈ 1200–1440 for content pages) and apply it everywhere.
The reference app applies it in exactly one place (login).

### Step 6 — Move actions, don't drop them

Build a small helper so the FAB→header conversion is impossible to get half-done:

```dart
({Widget? fab, List<Widget>? appBarActions, Widget? headerAction}) primaryActionsFor(
    BuildContext context, {required Widget Function() button}) {
  final wide = modeOf(...) == LayoutMode.expanded;
  return (fab: wide ? null : button(), appBarActions: wide ? null : [...], headerAction: wide ? button() : null);
}
```

Then audit: for every screen, confirm the primary action exists in **both** branches.

### Step 7 — Grid and table rules

- One ladder, one place: `const kGridLadder = {1200: 3, 700: 2, 0: 1};` — override only with a
  written reason.
- Tables: define at least one *optional* column pair that hides below a threshold. The reference
  app's `hideStatus` is the sole precedent (`simple_vehicles_view.dart:29,45`).
- Prefer filling available height over `height * 0.8`.

### Step 8 — Forms and the keyboard

- Always read `MediaQuery.viewInsetsOf(context).bottom` for the bottom action bar, or use
  `AnimatedPadding`. Do not use `padding.bottom` (safe area) for keyboard avoidance — this is a
  live bug in the reference app.
- Decide once whether the action bar is sticky; do not let it depend on orientation
  (the `stickyActions` bug).
- Keep the form in a scroll view in **both** orientations.
- Hoist any `ScrollController` to the parent so scroll position survives a branch swap.
- Prefer `LayoutBuilder` on a 2-column field row: if the row's width is < ~480, stack instead of
  forcing two half-width inputs. The reference app always shows 2 columns in reports
  (`build_create_report_fields_row.dart:13-16`) — a known weakness.

### Step 9 — State that must survive a resize

Verify each of these explicitly for every form/detail screen:

- [ ] Text controllers (put them on controllers, not in `State`)
- [ ] Selected tab / wizard step (use `Rx` + a stable `PageController`, or `PageStorageKey`)
- [ ] Scroll offset (hoist the `ScrollController`)
- [ ] Selection / checked items (put them on controllers)
- [ ] Sort + page state of tables (already controller-owned in the reference app)
- [ ] Focused field

### Step 10 — Verify (see §J)

---

## J. Verification checklist for the target application

Run the target app at each of these sizes. Mark ☑ only if you have actually looked.

### J.1 Sizes to test

| Class | Logical size | What it exercises |
|---|---|---|
| Small phone | `320 × 568` | Minimum support, longest translations |
| Phone | `375 × 812` | Design reference |
| Phone landscape | `740 × 360` | **The killer case** — must stay in the phone layout |
| Small tablet portrait | `768 × 1024` | Medium design canvas, 2-column grids |
| Small tablet landscape | `834 × 1194`→`1194 × 834` | Right at the native threshold |
| Large tablet landscape | `1366 × 1024` | Wide layout on native |
| Narrow window | `1024 × 768` | Below the desktop threshold — must be the compact layout |
| Threshold window | `1279 × 800` and `1281 × 800` | Verify the switch is clean |
| Desktop | `1440 × 900` | Design reference for wide |
| Wide desktop | `1920 × 1080` | Rail expanded, 3-column grids |
| Ultra-wide / 4K | `2560 × 1440` | Clamping, no runaway scaling |
| Short desktop window | `1440 × 500` | Vertical compression |
| Browser with devtools open | `1280 × 600` | Live resize, no jank |

### J.2 Per-screen checks

- [ ] No horizontal overflow at any size (check the console for `RenderFlex overflowed`).
- [ ] No text clipping or ellipsis on translated labels; check the longest string in each locale.
- [ ] Readable line length: no text block wider than ~75 characters on desktop.
- [ ] Every primary action reachable in **both** orientations.
- [ ] No `height * fraction` layout that can produce a negative or tiny box.
- [ ] The `EmptyDataWidget` / error state fits without scrolling at the shortest height.

### J.3 Behavioural checks

- [ ] Resize the browser window across a breakpoint: layout flips, no crash, no data refetch storm.
- [ ] Rotate a device with a form open: values, step, and scroll position survive.
- [ ] Rotate with a table open: page, sort, and selection survive.
- [ ] Rotate with a map open: panel state, zoom, and camera survive.
- [ ] Open the keyboard on every form: the focused field and the submit button stay reachable.
- [ ] Switch language at each size: no overflow, correct mirroring.
- [ ] Toggle RTL: drawer opens from the correct side, all padding mirrors, FAB relocates.
- [ ] Collapse/expand the nav rail: content re-measures, nothing is clipped.
- [ ] Keyboard-only navigation (if web is a target): every control reachable, focus visible.

### J.4 Performance checks

- [ ] No `IntrinsicHeight`/`IntrinsicWidth` wrapping lists, tables or scroll views.
- [ ] List item builders are cheap; no `MediaQuery` reads inside `itemBuilder`.
- [ ] Resize does not re-fetch data — layout and data must be independent.
- [ ] Long lists (1000+ items) do not jank on resize; consider a `ScrollController` restore.

### J.5 Code-level checks

- [ ] Exactly one layout-mode getter; grep for `isLandscape`, `Orientation.` and hard-coded width
      literals and confirm every hit is intentional.
- [ ] Every `LayoutBuilder`/`constraints.maxWidth` use is inside the box it sizes — no
      `context.width` inside a constrained panel.
- [ ] One breakpoint ladder constant, referenced by every grid.
- [ ] One content maximum-width constant, applied by the scaffold.
- [ ] `MediaQuery.viewInsetsOf` in every form, `MediaQuery.paddingOf` only for safe areas.
- [ ] No `kIsWeb` check that is really a width check.

---

## K. Summary

### Most useful patterns to adopt

1. **One boolean selects two complete widget trees.** `context.isAppLandscape` +
   `CustomOrientationWidget`. It guarantees the wide layout is *designed*, not stretched, and it
   makes the switch trivially auditable.
2. **Platform-aware thresholds.** 840 px for native landscape, 1080 px for browser/desktop. The
   intent — "a window-based platform has no real orientation, so require more width" — is
   correct and worth copying deliberately.
3. **Shared list views that encapsulate header + search + filter + toggle + table/grid +
   pagination.** `ContentTabbedLandscapeViewPage` and `GenericPagedView` are what makes ~16
   index screens consistent with almost no per-screen code.
4. **A 2–3 column wide detail pattern** built from `Row(crossAxisAlignment: .start) +
   Expanded(…Expanded) + SizedBox(16)` with tabs removed. Twelve screens use it.
5. **Side-panel forms**: `min(240, width*0.14)` stepper sidebar + animated content card, replacing
   a stepper-above-`PageView` on mobile.
6. **Map: `SlidingUpPanel` → fixed side card + info column**, with an explicit width ladder
   (1200/1450/1700) and an "info card hidden below 1200" rule.
7. **Clamped popovers** for filters: `(w*0.5).clamp(min, w - 32)`, anchored overlay in wide, sheet
   in narrow.
8. **Freeze scaling in the wide layout.** `DrawerScale` / raw dp for chrome, `.r` for content —
   this is what stops a 1440 px design from shrinking on a 1920 px display.
9. **A shared empty/error widget with a landscape variant and a 720 px typography switch.** Cheap,
   and the most consistently applied rule in the app.

### Exceptions that matter

- **`maxPortraitWidth = 600` was designed and never enabled.** Every "narrow" layout stretches on
  portrait tablets and on browser windows under the wide threshold.
- **Content is sized from the window while a 48–237 px rail is subtracted.** One screen
  compensates; the rest do not. This is the single most common cause of the "half-stretched
  desktop" look.
- **Three different orientation booleans** (`isAppLandscape`, `isLandscape`, `isWebLayout` where
  the last provably equals the second) coexist, so a 640–839 px landscape phone gets the wide
  layout with portrait chrome.
- **A 900 px table seed** conflicts with the 1080 px layout switch, producing portrait+table
  between 900 and 1080 px.
- **Grid ladders disagree within a single screen** (`{900,600}` in wide vs `{1400,840}` in narrow).
- **Landscape frequently drops actions** (FAB and app-bar actions nulled with no replacement) in
  job details, driver details and bus-route details.
- **Two forms have no wide layout at all** (vehicle-group create/edit) and one ignores
  `viewInsets` so its submit bar hides under the keyboard.
- **Shared detail components branch on nothing** and are used by 1–3 screens each; four screens
  roll their own detail row. Do not assume a "design system" exists — it does not.
- **No keyboard focus support anywhere**, no filter side-panel, no per-width table columns.

### Analysis limitations

1. **No runtime verification.** No device, emulator or browser was launched. Everything is
   code-derived; no claim in this document is `[VERIFIED]`.
2. **Rendering-library behaviour is assumed, not measured.** `ScreenUtil`'s `.r`/`.sp` formulas
   and `DataTable2`'s internal horizontal scrolling come from the `playx` and `data_table_2`
   packages, whose sources were not read. The *declaration* that a table scrolls horizontally is
   observed; the visual result is not.
3. **`playx` internals were not audited.** `PlatformScaffold`, `PlatformAppBar`, `ToggleSwitch`,
   `CustomModal`, `KeyboardVisibilityBuilder`, `WebScrollBlocker`, `PointerInterceptor` and
   `PaginatorController` all come from `playx`. Where this document says they behave a certain
   way, it is inferred from call sites, not from their source.
4. **Screen coverage.** All 64 routes and 10 in-app non-routed screens were located from
   `app_routes.dart` and `app_pages.dart` and their view files read. Leaf widget files were read
   selectively — roughly 120 Dart files were inspected out of the repository, weighted towards
   views, shared layout widgets and controllers. Deep leaf widgets (charts, map markers, chips)
   were covered where they carried a breakpoint.
5. **`lib/app/commands/` has no UI** — it is a data-layer module. Command UI lives under
   `lib/app/vehicles/ui/shared/commands/`.
6. **`NavigationView` is a stub** (`build => Container()`), so there is no in-app navigation
   layout to document.
7. **Two modules were not separately inspected**: the app-tour/showcase system
   (`core/ui/widgets/tour/`) and the video module beyond its platform FAB split. Neither was
   found to contain an independent breakpoint system, but neither was exhaustively read.
