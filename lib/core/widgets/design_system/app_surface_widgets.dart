part of '../widgets.dart';

enum AppTone { primary, success, warning, danger, info, gold, neutral }

class AppToneStyle {
  const AppToneStyle({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

AppToneStyle appToneStyle(BuildContext context, AppTone tone) {
  final colors = context.colors;
  return switch (tone) {
    AppTone.primary || AppTone.success => AppToneStyle(
      foreground: colors.primary,
      background: colors.primaryPale,
      border: AppColors.kLandscapePrimaryLine,
    ),
    AppTone.warning => AppToneStyle(
      foreground: AppColors.kLandscapeWarning,
      background: AppColors.kLandscapeWarningPale,
      border: AppColors.kLandscapeWarningLine,
    ),
    AppTone.danger => AppToneStyle(
      foreground: AppColors.kLandscapeDanger,
      background: AppColors.kLandscapeDangerPale,
      border: AppColors.kLandscapeDangerLine,
    ),
    AppTone.info => AppToneStyle(
      foreground: AppColors.kLandscapeInfo,
      background: AppColors.kLandscapeInfoPale,
      border: AppColors.kLandscapeInfoLine,
    ),
    AppTone.gold => AppToneStyle(
      foreground: AppColors.kLandscapeGold,
      background: AppColors.kLandscapeGoldPale,
      border: AppColors.kLandscapeGoldLine,
    ),
    AppTone.neutral => AppToneStyle(
      foreground: colors.textSecondary,
      background: colors.surfaceMuted,
      border: colors.border,
    ),
  };
}

/// Base surface: white card, hairline border, token radius and optional ink.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.radius = AppDesignRadius.card,
    this.onTap,
    this.shadow,
    this.clipBehavior = Clip.antiAlias,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final Clip clipBehavior;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: shadow,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Titled section with a consistent header, action area, and content rhythm.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    required this.child,
    this.padding,
    this.contentSpacing = AppSpacing.md,
    this.showDivider = false,
    this.tone = AppTone.primary,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets? padding;
  final double contentSpacing;
  final bool showDivider;
  final AppTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    final toneStyle = appToneStyle(context, tone);
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        if (icon != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: toneStyle.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: toneStyle.foreground),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );

    final hasActions = actions.isNotEmpty;
    final headerAndActions = hasActions
        ? LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    header,
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: actions,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  Expanded(child: header),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
                ],
              );
            },
          )
        : header;

    return AppSurface(
      padding: padding ?? factor.cardPadding,
      shadow: AppShadow.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          headerAndActions,
          if (showDivider) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.colors.divider),
            SizedBox(height: contentSpacing),
          ] else
            SizedBox(height: contentSpacing),
          child,
        ],
      ),
    );
  }
}

/// KPI card used across the dashboard, operations, and reports.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.tone = AppTone.primary,
    this.onTap,
    this.trailing,
    this.highlight = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final AppTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlight;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toneStyle = appToneStyle(context, tone);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            if (icon != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: highlight
                      ? Colors.white.withValues(alpha: 0.14)
                      : toneStyle.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: highlight ? Colors.white : toneStyle.foreground,
                ),
              ),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: highlight
                ? Colors.white.withValues(alpha: 0.78)
                : colors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            alignment: AlignmentDirectional.centerStart,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: context.textTheme.headlineSmall?.copyWith(
                color:
                    valueColor ?? (highlight ? Colors.white : colors.onSurface),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: highlight
                  ? Colors.white.withValues(alpha: 0.7)
                  : toneStyle.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    if (highlight) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(AppDesignRadius.card),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      shadow: AppShadow.soft,
      child: content,
    );
  }
}

class AppStatGrid extends StatelessWidget {
  const AppStatGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => AppResponsiveGrid(
    minItemWidth: minItemWidth,
    maxColumns: maxColumns,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: children,
  );
}

/// Small status pill with a semantic tint.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.status,
    this.label,
    this.compact = false,
  });

  final String status;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = appStatusStyle(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppDesignRadius.pill),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label ?? appStatusLabel(status),
            style: TextStyle(
              color: style.foreground,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

AppToneStyle appStatusStyle(BuildContext context, String status) {
  return switch (status.toLowerCase()) {
    'pending' ||
    'awaiting' ||
    'under_review' => appToneStyle(context, AppTone.warning),
    'approved' ||
    'active' ||
    'settled' ||
    'confirmed' ||
    'paid' ||
    'completed' ||
    'deducted' ||
    'inflow' ||
    'collection_inflow' => appToneStyle(context, AppTone.success),
    'rejected' ||
    'failed' ||
    'declined' ||
    'overdue' ||
    'outflow' => appToneStyle(context, AppTone.danger),
    'issued' || 'returned' || 'normal' => appToneStyle(context, AppTone.info),
    'instant' => appToneStyle(context, AppTone.gold),
    _ => appToneStyle(context, AppTone.neutral),
  };
}

String appStatusLabel(String status) => switch (status.toLowerCase()) {
  'pending' || 'awaiting' || 'under_review' => 'قيد الاعتماد',
  'approved' => 'معتمد',
  'active' => 'نشط',
  'inactive' => 'غير نشط',
  'rejected' => 'مرفوض',
  'settled' => 'مسوّى',
  'confirmed' => 'مؤكد',
  'paid' => 'مدفوع',
  'completed' => 'مكتمل',
  'issued' => 'صادر',
  'overdue' => 'متأخر',
  'deducted' => 'تم الخصم',
  'returned' => 'مرتجع',
  'archived' => 'مؤرشف',
  'failed' => 'فشل',
  'declined' => 'مرفوض',
  'inflow' => 'إيداع',
  'outflow' => 'سحب',
  'collection_inflow' => 'تحصيل بنكي',
  'instant' => 'فوري',
  'normal' => 'عادي',
  _ => status,
};

/// Consistent list row for financial records and approval queues.
class AppRecordTile extends StatelessWidget {
  const AppRecordTile({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.icon,
    this.tone = AppTone.neutral,
    this.trailing,
    this.status,
    this.onTap,
    this.showDivider = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final IconData? icon;
  final AppTone tone;
  final Widget? trailing;
  final String? status;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toneStyle = appToneStyle(context, tone);
    final leading = icon == null
        ? null
        : Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: toneStyle.background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: toneStyle.foreground),
          );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        if (meta != null && meta!.isNotEmpty)
          Text(
            meta!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
    final chip = status == null
        ? null
        : AppStatusChip(status: status!, compact: true);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 430;
        if (stacked && (chip != null || trailing != null)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  ?leading,
                  Expanded(child: titleBlock),
                  ?chip,
                ],
              ),
              if (trailing != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: leading == null ? 0 : 34 + AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            ?leading,
            Expanded(child: titleBlock),
            ?chip,
            ?trailing,
          ],
        );
      },
    );

    return Column(
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: dense ? 6 : 9,
                horizontal: 4,
              ),
              child: content,
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.7)),
      ],
    );
  }
}

/// Horizontal comparison bar used by dashboard charts.
class AppProgressRow extends StatelessWidget {
  const AppProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.ratio,
    this.tone = AppTone.primary,
    this.valueColor,
  });

  final String label;
  final String value;
  final double ratio;
  final AppTone tone;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = appToneStyle(context, tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: context.textTheme.bodySmall?.copyWith(
                  color: valueColor ?? context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignRadius.pill),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.colors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(style.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline informational banner for hints, warnings, and empty contexts.
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppTone.info,
    this.action,
  });

  final String message;
  final IconData icon;
  final AppTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final style = appToneStyle(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppDesignRadius.control),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Icon(icon, size: 18, color: style.foreground),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: style.foreground,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
