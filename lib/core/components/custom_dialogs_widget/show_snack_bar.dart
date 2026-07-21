import 'package:base/core/constants/enums/msg_type_enum.dart';
import 'package:base/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:base/core/constants/routes.dart';
import 'package:base/core/services/logging_service.dart';

class AppToast {
  static OverlayEntry? _current;

  static void showToast({
    required String message,
    MsgType type = MsgType.info,
    Function()? onTap,
    Duration duration = const Duration(seconds: 2),
  }) {
    try {
      final overlay = AppRoutes.key.currentState?.overlay;
      if (overlay == null) return;

      if (_current != null) {
        try {
          if (_current!.mounted) _current!.remove();
        } catch (_) {}
        _current = null;
      }

      final color = switch (type) {
        MsgType.error => AppColors.kRed,
        MsgType.success => AppColors.kMain,
        _ => AppColors.kBlack,
      };

      final entry = OverlayEntry(
        builder: (_) => _ToastWidget(message: message, color: color),
      );

      _current = entry;
      overlay.insert(entry);

      Future.delayed(duration, () {
        if (_current == entry) {
          try {
            if (entry.mounted) entry.remove();
          } catch (_) {}
          _current = null;
        }
      });
    } catch (e) {
      LoggingService.showMsg('AppToast Exception: $e');
    }
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final Color color;

  const _ToastWidget({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99999),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
