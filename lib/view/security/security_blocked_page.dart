import 'package:base/core/core.dart';
import 'package:flutter/material.dart';

class SecurityBlockedPage extends StatelessWidget {
  final DeviceSecurityStatus status;

  const SecurityBlockedPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
   

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding.left,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: EdgeInsets.all(AppDimensions.screenPadding.left),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: AppDimensions.radiusLg,
                border: Border.all(
                  color: context.theme.colorScheme.outline.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(status.icon, size: 38.sp, color: context. theme.colorScheme.error),
                  ),
                  SizedBox(height: AppDimensions.md * 1.5),
                  Text(
                    status.title,
                    style: context.theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.md * 0.5),
                  Text(
                    status.description,
                    style: context.theme.textTheme.bodyLarge?.copyWith(
                      color: context.theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
