part of 'security.dart';

abstract interface class DeviceSecurityService {
  Future<DeviceSecurityStatus> check();
}

class DeviceSecurityServiceImpl implements DeviceSecurityService {
  @override
  Future<DeviceSecurityStatus> check() async {
    try {
      final detection = JailbreakRootDetection.instance;
      final issues = await detection.checkForIssues;
      final isJailBroken = await detection.isJailBroken;
      final isRealDevice = await detection.isRealDevice;
      final isDeveloperMode =
          Platform.isAndroid ? await detection.isDevMode : false;
      final isOnExternalStorage =
          Platform.isAndroid ? await detection.isOnExternalStorage : false;

      LoggingService.showMsg(
        'Security check: issues=${issues.map((issue) => issue.name).toList()}, '
        'jailbroken=$isJailBroken, realDevice=$isRealDevice, '
        'developerMode=$isDeveloperMode, '
        'externalStorage=$isOnExternalStorage',
      );

      if (isJailBroken ||
          issues.any(
            (issue) =>
                issue == JailbreakIssue.jailbreak ||
                issue == JailbreakIssue.fridaFound ||
                issue == JailbreakIssue.cydiaFound ||
                issue == JailbreakIssue.tampered ||
                issue == JailbreakIssue.reverseEngineered,
          )) {
        return DeviceSecurityStatus.rootedOrJailbroken;
      }

      if (isDeveloperMode || issues.contains(JailbreakIssue.devMode)) {
        return DeviceSecurityStatus.developerModeEnabled;
      }

      if (!isRealDevice || issues.contains(JailbreakIssue.notRealDevice)) {
        return DeviceSecurityStatus.emulatorOrSimulator;
      }

      if (isOnExternalStorage ||
          issues.contains(JailbreakIssue.onExternalStorage) ||
          issues.contains(JailbreakIssue.proxied) ||
          issues.contains(JailbreakIssue.debugged)) {
        return DeviceSecurityStatus.untrustedDevice;
      }

      return DeviceSecurityStatus.safe;
    } catch (_) {
      return DeviceSecurityStatus.securityCheckFailed;
    }
  }
}
