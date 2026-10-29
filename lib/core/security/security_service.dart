part of 'security.dart';

abstract interface class DeviceSecurityService {
  Future<DeviceSecurityStatus> check();
}

class DeviceSecurityServiceImpl implements DeviceSecurityService {
  @override
  Future<DeviceSecurityStatus> check() async {
    try {
      if (kDebugMode) return DeviceSecurityStatus.safe;
      final detection = JailbreakRootDetection.instance;
      final issues = await detection.checkForIssues;
      final isJailBroken = await detection.isJailBroken;
      final isRealDevice = await detection.isRealDevice;
      final isDeveloperMode = Platform.isAndroid
          ? await detection.isDevMode
          : false;
      final isOnExternalStorage = Platform.isAndroid
          ? await detection.isOnExternalStorage
          : false;

      LoggingService.showMsg(
        'Security check: issues=${issues.map((issue) => issue.name).toList()}, '
        'jailbroken=$isJailBroken, realDevice=$isRealDevice, '
        'developerMode=$isDeveloperMode, '
        'externalStorage=$isOnExternalStorage',
      );

      // The iOS simulator can be reported by the plugin as both
      // `notRealDevice` and `tampered`. Classify the environment first so a
      // simulator is never misreported as a jailbroken physical device.
      if (!isRealDevice || issues.contains(JailbreakIssue.notRealDevice)) {
        const allowSimulatorForTesting = bool.fromEnvironment(
          'CREDEXA_ALLOW_SIMULATOR_FOR_TESTING',
          defaultValue: false,
        );
        if (kDebugMode && allowSimulatorForTesting) {
          return DeviceSecurityStatus.safe;
        }
        return DeviceSecurityStatus.emulatorOrSimulator;
      }

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
