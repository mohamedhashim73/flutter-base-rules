part of '../widgets.dart';

class AppTableColumn<T> {
  const AppTableColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cell;
  final int flex;
  final AlignmentGeometry alignment;
}

/// Responsive data table: real columns on wide screens, readable cards on
/// phones. Both presentations render the same rows and preserve RTL layout.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyLabel = 'لا توجد سجلات لعرضها.',
    this.onRowTap,
    this.compactBreakpoint = 760,
  });

  final List<AppTableColumn<T>> columns;
  final List<T> rows;
  final String emptyLabel;
  final void Function(T row)? onRowTap;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (rows.isEmpty) {
          return AppStateView(
            icon: Icons.inbox_outlined,
            title: emptyLabel,
            compact: true,
          );
        }
        if (constraints.maxWidth < compactBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              for (final row in rows)
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  onTap: onRowTap == null ? null : () => onRowTap!(row),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.xs,
                    children: [
                      for (var index = 0; index < columns.length; index++)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: 104,
                              child: Text(
                                columns[index].label,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: columns[index].alignment,
                                child: columns[index].cell(context, row),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: context.colors.surfaceMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 11,
                  ),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final column in columns)
                        Expanded(
                          flex: column.flex,
                          child: Align(
                            alignment: column.alignment,
                            child: Text(
                              column.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var index = 0; index < rows.length; index++)
                  _AppTableRow<T>(
                    row: rows[index],
                    columns: columns,
                    isLast: index == rows.length - 1,
                    onTap: onRowTap == null ? null : () => onRowTap!(rows[index]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppTableRow<T> extends StatelessWidget {
  const _AppTableRow({
    required this.row,
    required this.columns,
    required this.isLast,
    this.onTap,
  });

  final T row;
  final List<AppTableColumn<T>> columns;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: context.colors.divider.withValues(alpha: 0.75),
                    ),
                  ),
          ),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              for (final column in columns)
                Expanded(
                  flex: column.flex,
                  child: Align(
                    alignment: column.alignment,
                    child: DefaultTextStyle(
                      style:
                          context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurface,
                          ) ??
                          const TextStyle(),
                      child: column.cell(context, row),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
