import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/view/auth/ui/controllers/auth_cubit/auth_cubit.dart';
import 'package:base/view/auth/ui/controllers/auth_cubit/auth_states.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.cubit});

  final AuthCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: BlocListener<AuthCubit, AuthState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.status == RequestStatus.failure && state.message != null) {
            AppToast.showToast(message: state.message!, type: MsgType.error);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!AppBreakpoints.isCompact(context))
              const Expanded(flex: 5, child: _AuthBrandPanel()),
            Expanded(
              flex: 6,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppBreakpoints.isCompact(context)
                          ? AppSpacing.lg
                          : AppSpacing.xxl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppBreakpoints.isCompact(context) ? 440 : 600,
                      ),
                      child: _LoginFormWidget(cubit: cubit),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.sidebar),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'كريديكسا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Credixa · Finance',
                    style: TextStyle(
                      color: Color(0xFFBCD6CB),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'منصة مالية واحدة\nلإدارة الائتمان والخزينة.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const Text(
            'تابع البطاقات والعمليات والتسويات والالتزامات من لوحة تحكم تنفيذية واحدة، مع أثر تدقيق لكل حركة مالية.',
            style: TextStyle(
              color: Color(0xFFBCD6CB),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _BrandPill(icon: Icons.credit_card_outlined, label: 'ائتمان'),
              _BrandPill(icon: Icons.account_balance_outlined, label: 'خزينة'),
              _BrandPill(icon: Icons.fact_check_outlined, label: 'اعتمادات'),
              _BrandPill(icon: Icons.insights_outlined, label: 'تقارير'),
            ],
          ),
          const Spacer(),
          const Text(
            '© كريديكسا — إدارة مالية مؤسسية',
            style: TextStyle(color: Color(0xFF9DBAAE), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppDesignRadius.pill),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9EEBCF)),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LoginFormWidget extends StatelessWidget {
  const _LoginFormWidget({required this.cubit});

  final AuthCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: cubit,
      builder: (context, state) {
        final isLoading = state.status == RequestStatus.loading;
        final title = state.isRegisterMode
            ? 'إنشاء حساب Credexa'
            : 'مرحباً بك في Credexa';
        return AppSurface(
          shadow: AppShadow.card,
          padding: EdgeInsets.all(
            AppBreakpoints.isCompact(context)
                ? AppSpacing.lg
                : AppBreakpoints.isExpanded(context)
                ? AppSpacing.xxxl
                : AppSpacing.xxl,
          ),
          child: Form(
            key: cubit.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (AppBreakpoints.isCompact(context)) ...[
                  Row(
                    spacing: AppSpacing.xs,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      Text(
                        'كريديكسا',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  state.isRegisterMode
                      ? 'أنشئ حسابك للوصول إلى أدوات الإدارة المالية.'
                      : 'سجّل الدخول للمتابعة إلى مساحة العمل المالية.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TxtFieldWidget(
                  label: 'البريد الإلكتروني',
                  hint: 'أدخل البريد الإلكتروني',
                  controller: cubit.emailController,
                  textInputType: TextInputType.emailAddress,
                ),
                TxtFieldWidget(
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  controller: cubit.passwordController,
                  isPassword: true,
                  textInputType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: AppSpacing.xs),
                BtnWidget(
                  title: state.isRegisterMode ? 'إنشاء الحساب' : 'تسجيل الدخول',
                  onTap: cubit.submit,
                  isLoading: isLoading,
                ),
                Center(
                  child: TextBtnWidget(
                    title: state.isRegisterMode
                        ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                        : 'ليس لديك حساب؟ إنشاء حساب الآن',
                    txtColor: context.colors.primary,
                    onTap: cubit.toggleMode,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
