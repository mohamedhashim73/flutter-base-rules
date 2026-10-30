part of '../widgets.dart';

enum AppPageShimmerType {
  dashboard,
  creditCards,
  operations,
  financialRecords,
  treasuryRecords,
  expenseRecords,
  withdrawalRecords,
  installmentRecords,
  checkRecords,
  settlementRecords,
  reports,
  list,
  approvals,
  users,
  catalogs,
}

/// Loading twins for the page-level layouts used by Credexa.
///
/// Each variant keeps the same broad geometry as its real page: statistic
/// cards, section cards, record rows, and responsive grid breakpoints remain
/// in place while their values are loading.
class AppPageShimmerWidget extends StatelessWidget {
  const AppPageShimmerWidget({super.key, required this.type});

  final AppPageShimmerType type;

  @override
  Widget build(BuildContext context) => switch (type) {
    AppPageShimmerType.dashboard => _dashboard(context),
    AppPageShimmerType.creditCards => _creditCards(context),
    AppPageShimmerType.operations => _operations(context),
    AppPageShimmerType.financialRecords => _financialRecords(context),
    AppPageShimmerType.treasuryRecords => _recordPage(
      context,
      sections: 3,
      rows: 4,
    ),
    AppPageShimmerType.expenseRecords => _recordPage(
      context,
      sections: 2,
      rows: 5,
    ),
    AppPageShimmerType.withdrawalRecords => _recordPage(
      context,
      sections: 1,
      rows: 6,
    ),
    AppPageShimmerType.installmentRecords => _recordPage(
      context,
      sections: 2,
      rows: 5,
    ),
    AppPageShimmerType.checkRecords => _recordPage(
      context,
      sections: 1,
      rows: 6,
    ),
    AppPageShimmerType.settlementRecords => _recordPage(
      context,
      sections: 2,
      rows: 5,
    ),
    AppPageShimmerType.reports => _reports(context),
    AppPageShimmerType.list => _list(context),
    AppPageShimmerType.approvals => _approvals(context),
    AppPageShimmerType.users => _users(context),
    AppPageShimmerType.catalogs => _catalogs(context),
  };

  Widget _dashboard(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 12, minItemWidth: 190, maxColumns: 4),
        _sectionGrid(factor, count: 1, minItemWidth: 520, rows: 5),
        _chartGrid(factor),
        _insightBanner(),
      ],
    );
  }

  Widget _creditCards(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 3, minItemWidth: 210, maxColumns: 3),
        _creditCardBody(factor),
        _sectionCard(factor, rows: 6, titleWidth: 230, showAction: true),
      ],
    );
  }

  Widget _operations(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 5, minItemWidth: 210, maxColumns: 4),
        _formSection(factor, forms: 2, fields: 4),
        _formSection(factor, forms: 2, fields: 5),
        _formSection(factor, forms: 3, fields: 4),
        _formSection(factor, forms: 2, fields: 5),
        _formSection(factor, forms: 4, fields: 4),
        _formSection(factor, forms: 3, fields: 4),
        _sectionCard(factor, rows: 7, titleWidth: 230),
      ],
    );
  }

  Widget _financialRecords(BuildContext context) {
    return _recordPage(context, sections: 2, rows: 5);
  }

  Widget _recordPage(
    BuildContext context, {
    required int sections,
    required int rows,
  }) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 2, minItemWidth: 240, maxColumns: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: factor.sectionSpacing,
          children: List.generate(
            sections,
            (_) => _sectionCard(factor, rows: rows, titleWidth: 210),
          ),
        ),
      ],
    );
  }

  Widget _reports(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 4, minItemWidth: 210, maxColumns: 4),
        _sectionCard(factor, rows: 5, titleWidth: 220),
        _sectionGrid(factor, count: 6, minItemWidth: 340, rows: 4),
      ],
    );
  }

  Widget _list(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _sectionCard(factor, rows: 8, titleWidth: 190);
  }

  Widget _approvals(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _banner(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: factor.sectionSpacing,
          children: List.generate(
            8,
            (_) => _sectionCard(factor, rows: 2, showRowActions: true),
          ),
        ),
      ],
    );
  }

  Widget _users(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _sectionCard(factor, rows: 6, titleWidth: 185);
  }

  Widget _catalogs(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    return _pageColumn(
      factor,
      children: [
        _statGrid(factor, count: 4, minItemWidth: 210, maxColumns: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: factor.sectionSpacing,
          children: List.generate(7, (_) => _toggleSection(factor)),
        ),
      ],
    );
  }

  Widget _creditCardBody(AppFormFactor factor) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = _sectionCard(factor, rows: 4, titleWidth: 100);
      final details = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: factor.sectionSpacing,
        children: [
          _sectionCard(factor, rows: 5, titleWidth: 150),
          _sectionCard(factor, rows: 4, titleWidth: 170),
        ],
      );
      if (constraints.maxWidth < 900) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: factor.sectionSpacing,
          children: [cards, details],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          SizedBox(width: 340, child: cards),
          Expanded(child: details),
        ],
      );
    },
  );

  Widget _chartGrid(AppFormFactor factor) => AppResponsiveGrid(
    minItemWidth: 340,
    maxColumns: 2,
    children: List.generate(5, (_) => _chartCard(factor)),
  );

  Widget _chartCard(AppFormFactor factor) => AppSurface(
    padding: factor.cardPadding,
    shadow: AppShadow.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          children: [
            const ShimmerItemWidget(width: 36, height: 36, radius: 10),
            const SizedBox(width: AppSpacing.sm),
            const ShimmerItemWidget(width: 170, height: 17, borderIsOn: false),
          ],
        ),
        for (final width in [0.88, 0.64, 0.76, 0.48])
          Row(
            children: [
              Expanded(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: width,
                  child: const ShimmerItemWidget(height: 13, borderIsOn: false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const ShimmerItemWidget(width: 68, height: 12, borderIsOn: false),
            ],
          ),
      ],
    ),
  );

  Widget _formSection(
    AppFormFactor factor, {
    required int forms,
    required int fields,
  }) => AppSurface(
    padding: factor.cardPadding,
    shadow: AppShadow.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerItemWidget(width: 36, height: 36, radius: 10),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  ShimmerItemWidget(width: 230, height: 17, borderIsOn: false),
                  ShimmerItemWidget(width: 190, height: 11, borderIsOn: false),
                ],
              ),
            ),
          ],
        ),
        AppResponsiveGrid(
          minItemWidth: 280,
          maxColumns: 2,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: List.generate(
            forms,
            (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                for (var index = 0; index < fields; index++)
                  ShimmerItemWidget(
                    height: index == fields - 1 ? 36 : 44,
                    radius: 8,
                    borderIsOn: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _insightBanner() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: AppGradients.brand,
      borderRadius: BorderRadius.circular(AppDesignRadius.card),
      boxShadow: AppShadow.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          children: [
            const ShimmerItemWidget(width: 40, height: 40, radius: 11),
            const SizedBox(width: AppSpacing.sm),
            const ShimmerItemWidget(width: 210, height: 17, borderIsOn: false),
          ],
        ),
        const ShimmerItemWidget(width: 300, height: 13, borderIsOn: false),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(
            4,
            (_) => const ShimmerItemWidget(width: 112, height: 34, radius: 9),
          ),
        ),
      ],
    ),
  );

  Widget _pageColumn(AppFormFactor factor, {required List<Widget> children}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: factor.sectionSpacing,
        children: children,
      );

  Widget _statGrid(
    AppFormFactor factor, {
    required int count,
    required double minItemWidth,
    required int maxColumns,
  }) => AppResponsiveGrid(
    minItemWidth: minItemWidth,
    maxColumns: maxColumns,
    children: List.generate(count, (_) => _statCard(factor)),
  );

  Widget _sectionGrid(
    AppFormFactor factor, {
    required int count,
    required double minItemWidth,
    required int rows,
  }) => AppResponsiveGrid(
    minItemWidth: minItemWidth,
    maxColumns: 2,
    children: List.generate(count, (_) => _sectionCard(factor, rows: rows)),
  );

  Widget _statCard(AppFormFactor factor) => AppSurface(
    height: factor.isCompact ? 104 : 118,
    padding: factor.cardPadding,
    shadow: AppShadow.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        const ShimmerItemWidget(width: 92, height: 11, borderIsOn: false),
        const ShimmerItemWidget(width: 148, height: 24, borderIsOn: false),
        const ShimmerItemWidget(width: 118, height: 10, borderIsOn: false),
      ],
    ),
  );

  Widget _sectionCard(
    AppFormFactor factor, {
    int rows = 4,
    double titleWidth = 170,
    bool showAction = false,
    bool showRowActions = false,
  }) => AppSurface(
    padding: factor.cardPadding,
    shadow: AppShadow.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerItemWidget(width: 36, height: 36, radius: 10),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  ShimmerItemWidget(
                    width: titleWidth,
                    height: 17,
                    borderIsOn: false,
                  ),
                  const ShimmerItemWidget(
                    width: 132,
                    height: 11,
                    borderIsOn: false,
                  ),
                ],
              ),
            ),
            if (showAction)
              const ShimmerItemWidget(width: 64, height: 28, radius: 8),
          ],
        ),
        for (var index = 0; index < rows; index++)
          Row(
            children: [
              const ShimmerItemWidget(width: 28, height: 28, radius: 8),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    ShimmerItemWidget(
                      width: index.isEven ? 220 : 160,
                      height: 13,
                      borderIsOn: false,
                    ),
                    ShimmerItemWidget(
                      width: index.isEven ? 146 : 108,
                      height: 10,
                      borderIsOn: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (showRowActions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    const ShimmerItemWidget(width: 52, height: 28, radius: 7),
                    const ShimmerItemWidget(width: 52, height: 28, radius: 7),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 4,
                  children: [
                    ShimmerItemWidget(
                      width: index.isEven ? 92 : 68,
                      height: 13,
                      borderIsOn: false,
                    ),
                    const ShimmerItemWidget(
                      width: 54,
                      height: 10,
                      radius: 5,
                      borderIsOn: false,
                    ),
                  ],
                ),
            ],
          ),
      ],
    ),
  );

  Widget _toggleSection(AppFormFactor factor) => AppSurface(
    padding: factor.cardPadding,
    shadow: AppShadow.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerItemWidget(width: 36, height: 36, radius: 10),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  ShimmerItemWidget(width: 170, height: 17, borderIsOn: false),
                  ShimmerItemWidget(width: 72, height: 11, borderIsOn: false),
                ],
              ),
            ),
          ],
        ),
        for (var index = 0; index < 3; index++)
          Row(
            children: [
              const ShimmerItemWidget(width: 28, height: 28, radius: 8),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    ShimmerItemWidget(
                      width: 180,
                      height: 13,
                      borderIsOn: false,
                    ),
                    ShimmerItemWidget(
                      width: 120,
                      height: 10,
                      borderIsOn: false,
                    ),
                  ],
                ),
              ),
              const ShimmerItemWidget(width: 38, height: 22, radius: 11),
            ],
          ),
      ],
    ),
  );

  Widget _banner() => AppSurface(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Row(
      children: [
        const ShimmerItemWidget(width: 28, height: 28, radius: 8),
        const SizedBox(width: AppSpacing.sm),
        const ShimmerItemWidget(width: 240, height: 13, borderIsOn: false),
      ],
    ),
  );
}
