import 'security_status.dart';
import 'security_service.dart';

class SecurityCheck {
  static Future<DeviceSecurityStatus> checkDeviceSecurity() async {
    return DeviceSecurityServiceImpl().check();
  }
}
