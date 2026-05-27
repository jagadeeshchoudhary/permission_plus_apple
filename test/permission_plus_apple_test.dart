import 'package:flutter_test/flutter_test.dart';
import 'package:permission_plus_apple/permission_plus_apple.dart';
import 'package:permission_plus_apple/permission_plus_apple_platform_interface.dart';
import 'package:permission_plus_apple/permission_plus_apple_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPermissionPlusApplePlatform
    with MockPlatformInterfaceMixin
    implements PermissionPlusApplePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PermissionPlusApplePlatform initialPlatform = PermissionPlusApplePlatform.instance;

  test('$MethodChannelPermissionPlusApple is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPermissionPlusApple>());
  });

  test('getPlatformVersion', () async {
    PermissionPlusApple permissionPlusApplePlugin = PermissionPlusApple();
    MockPermissionPlusApplePlatform fakePlatform = MockPermissionPlusApplePlatform();
    PermissionPlusApplePlatform.instance = fakePlatform;

    expect(await permissionPlusApplePlugin.getPlatformVersion(), '42');
  });
}
