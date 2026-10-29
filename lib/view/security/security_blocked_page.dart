import 'package:base/core/core.dart';
import 'package:flutter/material.dart';

class SecurityBlockedPage extends StatelessWidget {
  final DeviceSecurityStatus status;

  const SecurityBlockedPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppSurface(
                shadow: AppShadow.card,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: AppStateView(
                  icon: status.icon,
                  tone: AppTone.danger,
                  title: status.title,
                  message: status.description,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
