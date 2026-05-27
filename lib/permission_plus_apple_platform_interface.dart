import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'permission_plus_apple_method_channel.dart';

abstract class PermissionPlusApplePlatform extends PlatformInterface {
  /// Constructs a PermissionPlusApplePlatform.
  PermissionPlusApplePlatform() : super(token: _token);

  static final Object _token = Object();

  static PermissionPlusApplePlatform _instance = MethodChannelPermissionPlusApple();

  /// The default instance of [PermissionPlusApplePlatform] to use.
  ///
  /// Defaults to [MethodChannelPermissionPlusApple].
  static PermissionPlusApplePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PermissionPlusApplePlatform] when
  /// they register themselves.
  static set instance(PermissionPlusApplePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
