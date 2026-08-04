import 'package:flutter/material.dart';

enum DeviceSecurityStatus {
  safe,
  developerModeEnabled,
  rootedOrJailbroken,
  emulatorOrSimulator,
  untrustedDevice,
  securityCheckFailed;

  IconData get icon {
    switch (this) {
      case DeviceSecurityStatus.developerModeEnabled:
        return Icons.developer_mode_outlined;
      case DeviceSecurityStatus.rootedOrJailbroken:
        return Icons.security_update_warning_outlined;
      case DeviceSecurityStatus.emulatorOrSimulator:
        return Icons.devices_outlined;
      case DeviceSecurityStatus.untrustedDevice:
        return Icons.gpp_bad_outlined;
      case DeviceSecurityStatus.securityCheckFailed:
        return Icons.error_outline;
      case DeviceSecurityStatus.safe:
        return Icons.security_outlined;
    }
  }

  String get title {
    switch (this) {
      case DeviceSecurityStatus.developerModeEnabled:
        return 'Developer mode is enabled';
      case DeviceSecurityStatus.rootedOrJailbroken:
        return 'Unsupported device security';
      case DeviceSecurityStatus.emulatorOrSimulator:
        return 'Unsupported device environment';
      case DeviceSecurityStatus.untrustedDevice:
        return 'Device trust could not be verified';
      case DeviceSecurityStatus.securityCheckFailed:
        return 'Security check failed';
      case DeviceSecurityStatus.safe:
        return '';
    }
  }

  String get description {
    switch (this) {
      case DeviceSecurityStatus.developerModeEnabled:
        return 'For security reasons, this app cannot be used while Developer Options are enabled. Disable them in your device settings, then try again.';
      case DeviceSecurityStatus.rootedOrJailbroken:
        return 'This device appears to be rooted or jailbroken, which can reduce app security. The app cannot continue on this device.';
      case DeviceSecurityStatus.emulatorOrSimulator:
        return 'This app is not available on emulators or simulators. Please open it on a physical device to continue.';
      case DeviceSecurityStatus.untrustedDevice:
        return 'Device settings or modifications that may affect application security were detected. The app cannot continue on this device.';
      case DeviceSecurityStatus.securityCheckFailed:
        return 'The app could not complete the required security checks on this device. Please try again or contact support if the issue continues.';
      case DeviceSecurityStatus.safe:
        return '';
    }
  }
}
