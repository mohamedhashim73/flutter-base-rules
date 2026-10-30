import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/view/notifications/data/models/notifications_response_model.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_cubit.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_states.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;
  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<NotificationsCubit, NotificationsState>(
    bloc: _cubit,
    builder: (context, state) => AppPageScaffold(
      destination: AppDestination.notifications,
      title: 'مركز الإشعارات',
      subtitle: 'التنبيهات المالية والتفضيلات',
      onRefresh: _cubit.load,
      unreadNotifications: state.unreadCount,
      actions: [
        IconButton(
          tooltip: 'تفضيلات الإشعارات',
          onPressed: _showPreferences,
          icon: const Icon(Icons.tune_outlined),
        ),
        IconButton(
          tooltip: 'تحديث',
          onPressed: _cubit.load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: DataStateBuilderWidget(
        dataState: DataState(
          state: state,
          response: AppNotificationsResponseModel(state.items),
        ),
        onFailure: _cubit.load,
        widget: AppSectionCard(
          title: 'الإشعارات',
          subtitle:
              '${state.unreadCount} غير مقروء من ${state.items.length} إشعار',
          icon: Icons.notifications_none_rounded,
          showDivider: true,
          actions: [
            if (state.unreadCount > 0)
              AppStatusChip(
                status: 'pending',
                label: '${state.unreadCount} جديد',
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < state.items.length; index++)
                Builder(
                  builder: (context) {
                    final item = state.items[index];
                    return AppRecordTile(
                      icon: item.read
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      tone: item.read ? AppTone.neutral : AppTone.primary,
                      title: item.title,
                      subtitle: item.body,
                      meta: item.read ? 'مقروء' : 'غير مقروء',
                      showDivider: index != state.items.length - 1,
                      trailing: item.read
                          ? null
                          : TextButton(
                              onPressed: () => _cubit.markRead(item.id),
                              child: const Text('تمت القراءة'),
                            ),
                      onTap: () async {
                        if (!item.read) await _cubit.markRead(item.id);
                        if (mounted)
                          _openTarget(item.targetType, item.targetId);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );

  void _openTarget(String targetType, String targetId) {
    switch (targetType) {
      case 'credit_card':
        AppNavigation.go(AppDestination.creditCards);
        return;
      case 'credit_deposit':
      case 'bank_movement':
        AppNavigation.go(AppDestination.approvals);
        return;
      case 'settlement':
      case 'collection_request':
      case 'treasury_movement':
      case 'treasury_transfer':
      case 'personal_withdrawal':
      case 'expense':
      case 'installment_account':
      case 'issued_check':
        AppNavigation.go(AppDestination.operations);
        return;
    }
  }

  Future<void> _showPreferences() async {
    var preferences = await sl<NotificationPreferencesService>().get();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final colors = context.colors;
          return AppDialog(
            title: 'تفضيلات الإشعارات',
            actions: [
              BtnWidget(
                title: 'حفظ',
                onTap: () async {
                  await sl<NotificationPreferencesService>().save(preferences);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              BtnWidget(
                title: 'إلغاء',
                onTap: () => Navigator.of(context).pop(),
                backgroundColor: colors.card,
                borderColor: colors.border,
                color: colors.onSurface,
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _preferenceTile('الاعتمادات', preferences.approvals, (value) {
                  setState(
                    () => preferences = preferences.copyWith(approvals: value),
                  );
                }),
                _preferenceTile('الأقساط', preferences.installments, (value) {
                  setState(
                    () =>
                        preferences = preferences.copyWith(installments: value),
                  );
                }),
                _preferenceTile('الشيكات', preferences.checks, (value) {
                  setState(
                    () => preferences = preferences.copyWith(checks: value),
                  );
                }),
                _preferenceTile('التحصيلات', preferences.collections, (value) {
                  setState(
                    () =>
                        preferences = preferences.copyWith(collections: value),
                  );
                }),
                _preferenceTile('الإشعارات الفورية', preferences.push, (value) {
                  setState(
                    () => preferences = preferences.copyWith(push: value),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _preferenceTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    value: value,
    onChanged: onChanged,
  );
}
