import 'package:base/core/security/security_service.dart';
import 'package:base/core/security/security_status.dart';
import 'package:base/view/security/security_blocked_page.dart';
import 'package:flutter/material.dart';

class AppSecurityGate extends StatefulWidget {
  final Widget child;

  const AppSecurityGate({super.key, required this.child});

  @override
  State<AppSecurityGate> createState() => _AppSecurityGateState();
}

class _AppSecurityGateState extends State<AppSecurityGate>
    with WidgetsBindingObserver {
  DeviceSecurityStatus? _securityStatus;
  final DeviceSecurityService _securityService = DeviceSecurityServiceImpl();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runSecurityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runSecurityCheck();
    }
  }

  Future<void> _runSecurityCheck() async {
    final result = await _securityService.check();
    if (!mounted) return;
    final wasBlocked = _securityStatus != null;
    if (result != DeviceSecurityStatus.safe) {
      setState(() => _securityStatus = result);
    } else if (wasBlocked) {
      setState(() => _securityStatus = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_securityStatus != null) {
      return PopScope(
        canPop: false,
        child: SecurityBlockedPage(
          status: _securityStatus!,
        ),
      );
    }
    return widget.child;
  }
}
