part of '../widgets.dart';

/// Empty, error, and access-denied presentation.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.tone = AppTone.neutral,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final AppTone tone;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = appToneStyle(context, tone);
    final sizes = compact
        ? (icon: 44.0, gap: AppSpacing.sm)
        : (icon: 64.0, gap: AppSpacing.md);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: compact ? AppSpacing.md : AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: sizes.gap,
          children: [
            Container(
              width: sizes.icon,
              height: sizes.icon,
              decoration: BoxDecoration(
                color: style.background,
                shape: BoxShape.circle,
                border: Border.all(color: style.border),
              ),
              child: Icon(
                icon,
                size: compact ? 20 : 28,
                color: style.foreground,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? context.textTheme.titleSmall
                          : context.textTheme.titleMedium)
                      ?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
            ),
            if (message != null && message!.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message,
    this.compact = false,
    this.color,
  });

  final String? message;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: color ?? context.colors.primary,
              ),
            ),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Toolbar that keeps search and filters aligned on any width.
class AppToolbar extends StatelessWidget {
  const AppToolbar({
    super.key,
    this.search,
    this.filters = const [],
    this.actions = const [],
  });

  final Widget? search;
  final List<Widget> filters;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final hasLeading = search != null || filters.isNotEmpty;
    if (!hasLeading && actions.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final leading = Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (search != null)
              SizedBox(
                width: wide ? 300 : constraints.maxWidth,
                child: search!,
              ),
            ...filters,
          ],
        );
        final trailing = Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              if (hasLeading) leading,
              if (actions.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
            ],
          );
        }
        return Row(
          spacing: AppSpacing.md,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: leading),
            if (actions.isNotEmpty) trailing,
          ],
        );
      },
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
      ),
    );
  }
}
