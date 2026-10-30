part of '../widgets.dart';

/// The three form factors used across the app.
enum AppFormFactor { compact, medium, expanded }

class AppBreakpoints {
  static const double medium = 700;
  static const double expanded = 1100;

  static AppFormFactor of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expanded) return AppFormFactor.expanded;
    if (width >= medium) return AppFormFactor.medium;
    return AppFormFactor.compact;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == AppFormFactor.compact;
  static bool isExpanded(BuildContext context) =>
      of(context) == AppFormFactor.expanded;
}

extension AppFormFactorX on AppFormFactor {
  bool get isCompact => this == AppFormFactor.compact;
  bool get isMedium => this == AppFormFactor.medium;
  bool get isExpanded => this == AppFormFactor.expanded;
  bool get hasSidebar => this == AppFormFactor.expanded;

  EdgeInsets get pagePadding => switch (this) {
    AppFormFactor.compact => AppSpacing.pageCompact,
    AppFormFactor.medium => AppSpacing.pageMedium,
    AppFormFactor.expanded => AppSpacing.pageExpanded,
  };

  EdgeInsets get cardPadding => switch (this) {
    AppFormFactor.compact => AppSpacing.cardCompact,
    _ => AppSpacing.cardExpanded,
  };

  double get sectionSpacing => switch (this) {
    AppFormFactor.compact => AppSpacing.lg,
    _ => AppSpacing.xl,
  };

  double get gridSpacing => switch (this) {
    AppFormFactor.compact => AppSpacing.sm,
    _ => AppSpacing.md,
  };
}

/// Rebuilds a subtree with the current form factor without duplicating the
/// screen, its controllers, or its data loading.
class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AppFormFactor formFactor) builder;

  @override
  Widget build(BuildContext context) =>
      builder(context, AppBreakpoints.of(context));
}

/// Places children in as many equal columns as fit, capped by [maxColumns].
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 260,
    this.maxColumns = 3,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        if (!available.isFinite || available <= 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: runSpacing,
            children: children,
          );
        }
        final columns = (available / minItemWidth).floor().clamp(1, maxColumns);
        final width = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Two-column layout that collapses to a single column on compact screens.
class AppSplitLayout extends StatelessWidget {
  const AppSplitLayout({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 2,
    this.secondaryFlex = 1,
    this.breakpoint = 980,
    this.spacing = AppSpacing.xl,
  });

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing,
            children: [primary, secondary],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

/// Vertical rhythm helper used between page sections.
class AppSectionGap extends StatelessWidget {
  const AppSectionGap({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height ?? AppBreakpoints.of(context).sectionSpacing);
}
