import 'package:base/core/security/security_status.dart';
import 'package:base/core/theme/app_diemnsions.dart';
import 'package:flutter/material.dart';
import 'package:playx/playx.dart';

class SecurityBlockedPage extends StatelessWidget {
  final DeviceSecurityStatus status;

  const SecurityBlockedPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.bodyHSpace),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: EdgeInsets.all(AppDimensions.bodyHSpace),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: AppDimensions.max,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.16),
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
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(status.icon, size: 38.sp, color: accentColor),
                  ),
                  SizedBox(height: AppDimensions.vSpace * 1.5),
                  Text(
                    status.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.vSpace * 0.5),
                  Text(
                    status.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
