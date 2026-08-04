import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'dart:io';
import 'security_status.dart';

class SecurityCheck {
  static Future<DeviceSecurityStatus> checkDeviceSecurity() async {
    try {
      final detection = JailbreakRootDetection.instance;
      final isJailBroken = await detection.isJailBroken;
      final isNotTrust = await detection.isNotTrust;
      final isRealDevice = await detection.isRealDevice;
      final isDeveloperMode =
          Platform.isAndroid ? await detection.isDevMode : false;

      if (isJailBroken) {
        return DeviceSecurityStatus.rootedOrJailbroken;
      }

      if (isDeveloperMode) {
        return DeviceSecurityStatus.developerModeEnabled;
      }

      if (isNotTrust) {
        return DeviceSecurityStatus.untrustedDevice;
      }

      if (!isRealDevice) {
        return DeviceSecurityStatus.emulatorOrSimulator;
      }

      return DeviceSecurityStatus.safe;
    } catch (_) {
      return DeviceSecurityStatus.securityCheckFailed;
    }
  }
}
