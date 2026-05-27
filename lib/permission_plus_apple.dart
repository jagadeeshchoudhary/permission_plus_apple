
import 'permission_plus_apple_platform_interface.dart';

class PermissionPlusApple {
  Future<String?> getPlatformVersion() {
    return PermissionPlusApplePlatform.instance.getPlatformVersion();
  }
}
