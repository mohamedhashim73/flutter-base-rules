import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/domain/managed_user_model.dart';
import 'package:base/view/users/ui/controllers/users_cubit/users_cubit.dart';
import 'package:base/view/users/ui/controllers/users_cubit/users_states.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final UsersCubit _cubit;
  late final Future<bool> _managerFuture;
  @override
  void initState() {
    super.initState();
    _cubit = sl<UsersCubit>();
    _managerFuture = sl<FirebaseAuthService>().hasRole('manager');
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: AppDestination.users,
    title: 'المستخدمون والصلاحيات',
    subtitle: 'الأدوار والصلاحيات وإعدادات التذكير المالي',
    onRefresh: _cubit.load,
    actions: [
      IconButton(
        tooltip: 'تحديث',
        onPressed: _cubit.load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: FutureBuilder<bool>(
      future: _managerFuture,
      builder: (context, access) {
        if (access.connectionState != ConnectionState.done) {
          return const AppLoadingState(message: 'جارٍ التحقق من الصلاحيات...');
        }
        if (access.data != true) {
          return AppStateView(
            icon: Icons.lock_outline_rounded,
            tone: AppTone.danger,
            title: 'هذه الصفحة متاحة للمدير الرئيسي فقط',
            message: 'اطلب من المدير الرئيسي منحك صلاحية إدارة المستخدمين.',
          );
        }
        return BlocListener<UsersCubit, UsersState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state.actionMessage == null) return;
            if (state.actionStatus == RequestStatus.success ||
                state.actionStatus == RequestStatus.failure) {
              AppToast.showToast(
                message: state.actionMessage!,
                type: state.actionStatus == RequestStatus.failure
                    ? MsgType.error
                    : MsgType.success,
              );
            }
          },
          child: BlocBuilder<UsersCubit, UsersState>(
            bloc: _cubit,
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppBreakpoints.of(context).sectionSpacing,
              children: [
                _createForm(),
                const _NotificationSettingsCard(),
                DataStateBuilderWidget(
                  dataState: DataState(
                    state: state,
                    response: _UsersResponse(state.users),
                  ),
                  onFailure: _cubit.load,
                  widget: _list(context, state),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _createForm() => AppSectionCard(
    title: 'إنشاء مستخدم',
    subtitle: 'أضف عضواً جديداً وحدد دوره وصلاحياته',
    icon: Icons.person_add_alt_1_outlined,
    showDivider: true,
    child: Form(
      key: _cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          AppResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 3,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _field('الاسم', 'الاسم الظاهر', _cubit.displayNameController),
              _field(
                'البريد الإلكتروني',
                'name@example.com',
                _cubit.emailController,
              ),
              _field(
                'كلمة مرور مؤقتة',
                'كلمة المرور',
                _cubit.passwordController,
                password: true,
              ),
              DropDownBtnWidget<String>(
                label: 'الدور',
                hint: 'اختر الدور',
                value: _cubit.role,
                items: const ['employee', 'accountant', 'manager'],
                getLabel: (role) => role == 'employee'
                    ? 'موظف'
                    : role == 'accountant'
                    ? 'محاسب / مراجع'
                    : 'مدير رئيسي',
                onChanged: (value) => _cubit.role = value,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          AppResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 3,
            spacing: 0,
            runSpacing: 0,
            children: [
              _permissionCheckbox(
                'مراجعة التسويات',
                _cubit.settlementReview,
                (value) => setState(() => _cubit.settlementReview = value),
              ),
              _permissionCheckbox(
                'تعديل السجلات',
                _cubit.recordsEdit,
                (value) => setState(() => _cubit.recordsEdit = value),
              ),
              _permissionCheckbox(
                'مطابقة الخزينة',
                _cubit.treasuryReconcile,
                (value) => setState(() => _cubit.treasuryReconcile = value),
              ),
              _permissionCheckbox(
                'إدارة حسابات الخزينة',
                _cubit.treasuryAccountsManage,
                (value) =>
                    setState(() => _cubit.treasuryAccountsManage = value),
              ),
              _permissionCheckbox(
                'إدارة تصنيفات المصروفات',
                _cubit.expenseCategoriesManage,
                (value) =>
                    setState(() => _cubit.expenseCategoriesManage = value),
              ),
              _permissionCheckbox(
                'حذف السجلات',
                _cubit.recordsDelete,
                (value) => setState(() => _cubit.recordsDelete = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BtnWidget(title: 'إنشاء المستخدم', onTap: _cubit.createUser),
          ),
        ],
      ),
    ),
  );

  Widget _permissionCheckbox(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    value: value,
    onChanged: (next) => onChanged(next ?? false),
    title: Text(title),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
    visualDensity: VisualDensity.compact,
    controlAffinity: ListTileControlAffinity.leading,
  );
  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool password = false,
  }) => TxtFieldWidget(
    label: label,
    hint: hint,
    controller: controller,
    isPassword: password,
  );
  Widget _list(BuildContext context, UsersState state) => AppSectionCard(
    title: 'المستخدمون',
    subtitle: '${state.users.length} عضو مسجل',
    icon: Icons.manage_accounts_outlined,
    showDivider: true,
    tone: AppTone.info,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < state.users.length; index++)
          AppRecordTile(
            icon: Icons.person_outline_rounded,
            title: state.users[index].displayName,
            subtitle: state.users[index].email,
            meta: _roleLabel(state.users[index].role),
            status: state.users[index].active ? 'active' : 'inactive',
            showDivider: index != state.users.length - 1,
            trailing: IconButton(
              tooltip: 'تعديل الصلاحيات',
              onPressed: () => _showAccessDialog(state.users[index]),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          ),
      ],
    ),
  );

  String _roleLabel(String role) => switch (role) {
    'manager' => 'مدير رئيسي',
    'accountant' => 'محاسب / مراجع',
    'employee' => 'موظف',
    _ => role,
  };

  Future<void> _showAccessDialog(ManagedUserModel user) {
    var role = user.role;
    var permissions = <String, bool>{...user.permissions};
    return showAdaptiveDialogWidget(
      title: 'تعديل صلاحيات المستخدم',
      okTxt: 'حفظ الصلاحيات',
      content: _UserAccessForm(
        user: user,
        onChanged: (nextRole, nextPermissions) {
          role = nextRole;
          permissions = nextPermissions;
        },
      ),
      okTap: () => _cubit.updateUserAccess(
        uid: user.id,
        role: role,
        permissions: permissions,
      ),
    );
  }
}

class _NotificationSettingsCard extends StatefulWidget {
  const _NotificationSettingsCard();

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  final installmentController = TextEditingController();
  final checkController = TextEditingController();
  final approvalThresholdController = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await sl<FinanceSettingsService>()
          .getNotificationSettings();
      final approvalThreshold = await sl<FinanceSettingsService>()
          .getApprovalThresholdMinor();
      if (!mounted) return;
      installmentController.text =
          '${settings['installmentReminderDays'] ?? FinanceSettingsService.defaultReminderDays}';
      checkController.text =
          '${settings['checkReminderDays'] ?? FinanceSettingsService.defaultReminderDays}';
      approvalThresholdController.text = (approvalThreshold / 100)
          .toStringAsFixed(2);
    } catch (_) {
      installmentController.text =
          '${FinanceSettingsService.defaultReminderDays}';
      checkController.text = '${FinanceSettingsService.defaultReminderDays}';
      approvalThresholdController.text =
          (FinanceSettingsService.defaultApprovalThresholdMinor / 100)
              .toStringAsFixed(2);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    final installmentDays = int.tryParse(installmentController.text.trim());
    final checkDays = int.tryParse(checkController.text.trim());
    final approvalThreshold = FinanceMoney.parseToMinor(
      approvalThresholdController.text,
    );
    if (installmentDays == null ||
        checkDays == null ||
        installmentDays < 0 ||
        checkDays < 0 ||
        installmentDays > 60 ||
        checkDays > 60) {
      AppToast.showToast(
        message: 'أدخل مدة تذكير بين 0 و60 يوماً.',
        type: MsgType.error,
      );
      return;
    }
    if (approvalThreshold <= 0) {
      AppToast.showToast(
        message: 'أدخل حد اعتماد أكبر من صفر.',
        type: MsgType.error,
      );
      return;
    }
    setState(() => saving = true);
    try {
      await sl<FinanceSettingsService>().saveNotificationSettings(
        installmentReminderDays: installmentDays,
        checkReminderDays: checkDays,
      );
      await sl<FinanceSettingsService>().saveApprovalThresholdMinor(
        approvalThreshold,
      );
      if (!mounted) return;
      AppToast.showToast(
        message: 'تم حفظ إعدادات التذكير وحد الاعتماد.',
        type: MsgType.success,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.showToast(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: MsgType.error,
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    installmentController.dispose();
    checkController.dispose();
    approvalThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSectionCard(
    title: 'إعدادات التذكير المالي',
    subtitle: 'نافذة التذكير قبل الاستحقاق وحد الاعتماد للعمليات المالية.',
    icon: Icons.notifications_active_outlined,
    tone: AppTone.gold,
    showDivider: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        const AppInfoBanner(
          icon: Icons.schedule_outlined,
          tone: AppTone.info,
          message:
              'تحدد هذه القيم نافذة التذكير قبل الاستحقاق. التذكيرات المتأخرة تبقى فعالة حتى تسجيل السداد أو تحديث الحالة.',
        ),
        if (loading)
          const AppLoadingState(compact: true)
        else
          AppResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 3,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TxtFieldWidget(
                label: 'تذكير الأقساط قبل (يوم)',
                hint: '3',
                controller: installmentController,
                isNum: true,
                textInputType: TextInputType.number,
              ),
              TxtFieldWidget(
                label: 'حد اعتماد العمليات (جنيه)',
                hint: '5000.00',
                controller: approvalThresholdController,
                isNum: true,
                textInputType: TextInputType.number,
              ),
              TxtFieldWidget(
                label: 'تذكير الشيكات قبل (يوم)',
                hint: '3',
                controller: checkController,
                isNum: true,
                textInputType: TextInputType.number,
              ),
            ],
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BtnWidget(
            title: 'حفظ إعدادات التذكير',
            onTap: loading || saving ? null : _save,
            isLoading: saving,
          ),
        ),
      ],
    ),
  );
}

class _UserAccessForm extends StatefulWidget {
  const _UserAccessForm({required this.user, required this.onChanged});
  final ManagedUserModel user;
  final void Function(String role, Map<String, bool> permissions) onChanged;

  @override
  State<_UserAccessForm> createState() => _UserAccessFormState();
}

class _UserAccessFormState extends State<_UserAccessForm> {
  late String role = widget.user.role;
  late Map<String, bool> permissions = {...widget.user.permissions};

  void _changed() => widget.onChanged(role, {...permissions});

  Widget _permissionCheckbox(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    value: value,
    onChanged: (next) => onChanged(next ?? false),
    title: Text(title),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DropDownBtnWidget<String>(
        label: 'الدور',
        hint: 'اختر الدور',
        value: role,
        items: const ['employee', 'accountant', 'manager'],
        getLabel: (value) => value,
        onChanged: (value) {
          setState(() => role = value);
          _changed();
        },
      ),
      CheckboxListTile(
        value: permissions['settlements.review'] == true,
        onChanged: (value) {
          setState(() => permissions['settlements.review'] = value ?? false);
          _changed();
        },
        title: const Text('مراجعة التسويات'),
      ),
      CheckboxListTile(
        value: permissions['records.edit'] == true,
        onChanged: (value) {
          setState(() => permissions['records.edit'] = value ?? false);
          _changed();
        },
        title: const Text('تعديل السجلات'),
      ),
      _permissionCheckbox(
        'مطابقة الخزينة',
        permissions['treasury.reconcile'] == true,
        (value) {
          setState(() => permissions['treasury.reconcile'] = value);
          _changed();
        },
      ),
      _permissionCheckbox(
        'إدارة حسابات الخزينة',
        permissions['treasury.accounts.manage'] == true,
        (value) {
          setState(() => permissions['treasury.accounts.manage'] = value);
          _changed();
        },
      ),
      _permissionCheckbox(
        'إدارة تصنيفات المصروفات',
        permissions['expenses.categories.manage'] == true,
        (value) {
          setState(() => permissions['expenses.categories.manage'] = value);
          _changed();
        },
      ),
      _permissionCheckbox(
        'حذف السجلات',
        permissions['records.delete'] == true,
        (value) {
          setState(() => permissions['records.delete'] = value);
          _changed();
        },
      ),
    ],
  );
}

class _UsersResponse implements LoadableResponse<List<ManagedUserModel>> {
  const _UsersResponse(this.data);
  @override
  final List<ManagedUserModel> data;
}
