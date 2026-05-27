import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'permission_plus_apple_platform_interface.dart';

/// An implementation of [PermissionPlusApplePlatform] that uses method channels.
class MethodChannelPermissionPlusApple extends PermissionPlusApplePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('permission_plus_apple');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
