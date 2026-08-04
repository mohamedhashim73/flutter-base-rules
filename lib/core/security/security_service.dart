import 'dart:io';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'security_status.dart';

abstract interface class DeviceSecurityService {
  Future<DeviceSecurityStatus> check();
}

class DeviceSecurityServiceImpl implements DeviceSecurityService {
  @override
  Future<DeviceSecurityStatus> check() async {
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

      if (isNotTrust || !isRealDevice) {
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
