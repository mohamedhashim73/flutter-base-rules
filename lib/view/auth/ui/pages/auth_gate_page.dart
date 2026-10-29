import 'package:flutter/material.dart';
import 'package:base/core/core.dart';
import 'package:base/view/auth/ui/controllers/auth_cubit/auth_cubit.dart';
import 'package:base/view/auth/ui/pages/login_page.dart';
import 'package:base/view/dashboard/ui/pages/dashboard_page.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({
    super.key,
    required this.authService,
    required this.authCubit,
  });

  final FirebaseAuthService authService;
  final AuthCubit authCubit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: const AppLoadingState(message: 'جارٍ التحقق من الجلسة...'),
          );
        }
        return snapshot.data == null
            ? LoginPage(cubit: authCubit)
            : _AuthenticatedShell(authService: authService);
      },
    );
  }
}

class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell({required this.authService});
  final FirebaseAuthService authService;
  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  late final Future<void> _membershipFuture;
  @override
  void initState() {
    super.initState();
    _membershipFuture = widget.authService.refreshMembership();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _membershipFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          backgroundColor: context.colors.background,
          body: const AppLoadingState(message: 'جارٍ تحميل عضوية المؤسسة...'),
        );
      }
      if (widget.authService.hasMembership) return const DashboardPage();
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppSurface(
              shadow: AppShadow.card,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: AppStateView(
                icon: Icons.domain_disabled_outlined,
                tone: AppTone.warning,
                title: 'الحساب غير مرتبط بمؤسسة',
                message:
                    'تم إنشاء الحساب. يحتاج الحساب إلى عضوية مؤسسة قبل المتابعة.',
                action: FilledButton.icon(
                  onPressed: widget.authService.signOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
