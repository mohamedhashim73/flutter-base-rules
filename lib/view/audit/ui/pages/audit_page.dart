import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/view/audit/data/models/audit_response_model.dart';
import 'package:base/view/audit/ui/controllers/audit_cubit/audit_cubit.dart';
import 'package:base/view/audit/ui/controllers/audit_cubit/audit_states.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late final AuditCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AuditCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: AppDestination.audit,
    title: 'سجل التدقيق',
    subtitle: 'أثر التغييرات على السجلات المالية',
    onRefresh: _cubit.load,
    actions: [
      IconButton(
        tooltip: 'تحديث',
        onPressed: _cubit.load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: BlocBuilder<AuditCubit, AuditState>(
      bloc: _cubit,
      builder: (context, state) => DataStateBuilderWidget(
        dataState: DataState(
          state: state,
          response: AuditResponseModel(state.items),
        ),
        onFailure: _cubit.load,
        widget: AppSectionCard(
          title: 'الحركات المسجلة',
          subtitle: '${state.items.length} سجل تدقيق',
          icon: Icons.history_rounded,
          showDivider: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < state.items.length; index++)
                Builder(
                  builder: (context) {
                    final item = state.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuditExpandable(item: item),
                        if (index != state.items.length - 1)
                          Divider(height: 1, color: context.colors.divider),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AuditExpandable extends StatelessWidget {
  const _AuditExpandable({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxs,
        ),
        childrenPadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.xs,
          end: AppSpacing.xs,
          bottom: AppSpacing.md,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryPale,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 17,
            color: colors.primary,
          ),
        ),
        title: Text(
          '${item.action} · ${item.entityType}',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${item.entityId} · ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(item.createdAtMillis))}',
          style: context.textTheme.bodySmall,
        ),
        children: [
          if (item.reason.isNotEmpty)
            _AuditDetail(
              label: 'السبب',
              child: Text(item.reason, style: context.textTheme.bodySmall),
            ),
          if (item.previousValues.isNotEmpty)
            _AuditDetail(
              label: 'القيم السابقة',
              child: SelectableText(
                jsonEncode(item.previousValues),
                style: context.textTheme.bodySmall,
              ),
            ),
          if (item.newValues.isNotEmpty)
            _AuditDetail(
              label: 'القيم الجديدة',
              child: SelectableText(
                jsonEncode(item.newValues),
                style: context.textTheme.bodySmall,
              ),
            ),
          _AuditDetail(
            label: 'المصدر',
            child: Text(
              '${item.source} · ${item.createdBy}',
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditDetail extends StatelessWidget {
  const _AuditDetail({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppDesignRadius.control),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
        ),
        child,
      ],
    ),
  );
}
