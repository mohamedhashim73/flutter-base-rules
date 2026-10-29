part of '../widgets.dart';

/// Shared page shell used by every screen.
///
/// A single `Scaffold` hosts the adaptive navigation: an embedded sidebar on
/// wide screens, a compact rail on tablets, and a drawer on phones. Screens
/// keep their own state, controllers, and data loading; only presentation
/// changes with the form factor.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    this.destination,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.body,
    this.onRefresh,
    this.scrollable = true,
    this.maxWidth = AppSizes.maxContentWidth,
    this.padding,
    this.unreadNotifications = 0,
    this.floatingActionButton,
    this.leading,
  });

  final AppDestination? destination;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Future<void> Function()? onRefresh;
  final bool scrollable;
  final double maxWidth;
  final EdgeInsets? padding;
  final int unreadNotifications;
  final Widget? floatingActionButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: floatingActionButton,
      drawer: factor.isCompact
          ? Drawer(
              width: AppSizes.sidebarWidth + 20,
              backgroundColor: AppColors.kLandscapeSidebar,
              shape: const RoundedRectangleBorder(),
              child: AppSidebar(
                current: destination,
                onNavigate: (next) {
                  Navigator.of(context).pop();
                  AppNavigation.go(next);
                },
              ),
            )
          : null,
      body: Builder(
        builder: (shellContext) {
          final sidebar = AppSidebar(
            current: destination,
            rail: factor.isMedium,
            onNavigate: (next) {
              if (next == destination) return;
              AppNavigation.go(next);
            },
          );
          return SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!factor.isCompact) sidebar,
                Expanded(
                  child: Column(
                    children: [
                      AppTopBar(
                        destination: destination,
                        onMenu: factor.isCompact
                            ? () => Scaffold.of(shellContext).openDrawer()
                            : null,
                        unreadNotifications: unreadNotifications,
                      ),
                      Expanded(
                        child: _PageBody(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          body: body,
                          onRefresh: onRefresh,
                          scrollable: scrollable,
                          maxWidth: maxWidth,
                          padding: padding ?? factor.pagePadding,
                          leading: leading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.body,
    required this.onRefresh,
    required this.scrollable,
    required this.maxWidth,
    required this.padding,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Future<void> Function()? onRefresh;
  final bool scrollable;
  final double maxWidth;
  final EdgeInsets padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: title,
                subtitle: subtitle,
                actions: actions,
                leading: leading,
              ),
              SizedBox(height: AppBreakpoints.of(context).sectionSpacing),
              body,
            ],
          ),
        ),
      ),
    );
    if (!scrollable) return content;
    final scrollView = SingleChildScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      child: content,
    );
    if (onRefresh == null) return scrollView;
    return RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
  }
}

/// Page title, description, and actions.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final factor = AppBreakpoints.of(context);
    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                title,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (actions.isEmpty) return titleBlock;

    final actionRow = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );

    if (factor.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          titleBlock,
          Align(alignment: AlignmentDirectional.centerStart, child: actionRow),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: AppSpacing.lg,
      children: [
        Expanded(child: titleBlock),
        actionRow,
      ],
    );
  }
}

/// Persistent top bar with account menu and notification shortcut.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.destination,
    this.onMenu,
    this.unreadNotifications = 0,
  });

  final AppDestination? destination;
  final VoidCallback? onMenu;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final email = appUserEmail();
    return Container(
      height: AppSizes.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              tooltip: 'القائمة',
              onPressed: onMenu,
              icon: Icon(Icons.menu_rounded, color: colors.onSurface),
            ),
          if (onMenu == null) const SizedBox(width: AppSpacing.xs),
          Icon(Icons.hub_outlined, size: 18, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              destination?.label ?? 'كريديكسا',
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'مركز الإشعارات',
            onPressed: destination == AppDestination.notifications
                ? null
                : () => AppNavigation.go(AppDestination.notifications),
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              backgroundColor: colors.error,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          PopupMenuButton<String>(
            tooltip: 'حساب المستخدم',
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignRadius.control),
            ),
            onSelected: (value) {
              if (value == 'profile') showAppProfileDialog(context);
              if (value == 'logout') appSignOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(appUserRole(), style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  spacing: 10,
                  children: [Icon(Icons.person_outline), Text('الملف الشخصي')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  spacing: 10,
                  children: [Icon(Icons.logout_rounded), Text('تسجيل الخروج')],
                ),
              ),
            ],
            child: Row(
              spacing: AppSpacing.xs,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: colors.primaryPale,
                  child: Text(
                    appUserInitial(email),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (AppBreakpoints.of(context).isExpanded)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared session helpers for the shell and account menu.
String appUserEmail() {
  try {
    if (!sl.isRegistered<FirebaseAuthService>()) return 'حساب المستخدم';
    return sl<FirebaseAuthService>().currentUser?.email ?? 'حساب المستخدم';
  } catch (_) {
    return 'حساب المستخدم';
  }
}

String appUserRole() {
  try {
    if (!sl.isRegistered<FirebaseAuthService>()) return 'عضو المؤسسة';
    final role = sl<FirebaseAuthService>().role;
    return switch (role) {
      'manager' => 'مدير رئيسي',
      'accountant' => 'محاسب / مراجع',
      'employee' => 'موظف',
      _ => role ?? 'عضو المؤسسة',
    };
  } catch (_) {
    return 'عضو المؤسسة';
  }
}

String appUserInitial(String email) {
  final value = email.trim();
  return value.isEmpty ? 'C' : value.substring(0, 1).toUpperCase();
}

Future<void> appSignOut() async {
  await UserSessionService.emptyCache();
  if (sl.isRegistered<FirebaseAuthService>()) {
    await sl<FirebaseAuthService>().signOut();
  }
}

void showAppProfileDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('الملف الشخصي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _ProfileRow(
            icon: Icons.alternate_email_rounded,
            label: 'البريد الإلكتروني',
            value: appUserEmail(),
          ),
          _ProfileRow(
            icon: Icons.badge_outlined,
            label: 'الدور',
            value: appUserRole(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      Icon(icon, size: 18, color: context.colors.textSecondary),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.bodySmall),
            Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Deep-green navigation menu shared by the sidebar, rail, and drawer.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    this.current,
    this.rail = false,
    this.onNavigate,
  });

  final AppDestination? current;
  final bool rail;
  final ValueChanged<AppDestination>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final group in AppNavGroup.values) {
      final destinations = AppDestination.values
          .where((item) => item.group == group)
          .toList();
      if (destinations.isEmpty) continue;
      if (!rail) {
        items.add(
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: 22,
              top: items.isEmpty ? 4 : 20,
              bottom: 8,
            ),
            child: Text(
              group.label,
              style: TextStyle(
                color: AppColors.kLandscapeSidebarText.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        );
      } else if (items.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        );
      }
      for (final destination in destinations) {
        items.add(
          _SidebarItem(
            destination: destination,
            selected: destination == current,
            rail: rail,
            onTap: () => onNavigate?.call(destination),
          ),
        );
      }
    }

    return Container(
      width: rail ? AppSizes.sidebarRailWidth : AppSizes.sidebarWidth,
      decoration: const BoxDecoration(gradient: AppGradients.sidebar),
      child: Column(
        children: [
          _SidebarBrand(rail: rail),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: items,
            ),
          ),
          _SidebarFooter(rail: rail),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.rail});

  final bool rail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: rail ? 18 : 20, vertical: 18),
    child: Row(
      mainAxisAlignment: rail
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      spacing: 12,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.kLandscapePrimary.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        if (!rail)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                const Text(
                  'كريديكسا',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  'CREDIXA · FINANCE',
                  style: TextStyle(
                    color: AppColors.kLandscapeSidebarText.withValues(
                      alpha: 0.62,
                    ),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.rail,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final bool rail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: rail ? 12 : 12, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: rail ? 0 : 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
          ),
          child: Row(
            mainAxisAlignment: rail
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            spacing: 11,
            children: [
              if (selected && !rail)
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EE7B7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              Icon(
                destination.icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : AppColors.kLandscapeSidebarText.withValues(alpha: 0.82),
              ),
              if (!rail)
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.kLandscapeSidebarText.withValues(
                              alpha: 0.82,
                            ),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return rail ? Tooltip(message: destination.label, child: content) : content;
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.rail});

  final bool rail;

  @override
  Widget build(BuildContext context) {
    final email = appUserEmail();
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: const Color(0xFF1E4D40),
      child: Text(
        appUserInitial(email),
        style: const TextStyle(
          color: Color(0xFF9EEBCF),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
    final logout = IconButton(
      tooltip: 'تسجيل الخروج',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      onPressed: appSignOut,
      icon: Icon(
        Icons.logout_rounded,
        size: 18,
        color: AppColors.kLandscapeSidebarText.withValues(alpha: 0.85),
      ),
    );

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.all(rail ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: rail
          ? Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [avatar, logout],
            )
          : Row(
              spacing: 10,
              children: [
                avatar,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        appUserRole(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.kLandscapeSidebarText.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                logout,
              ],
            ),
    );
  }
}
