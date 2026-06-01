// Basic Flutter integration test for permission_plus_apple.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

import 'package:permission_plus_apple/permission_plus_apple.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkPermission returns a valid status', (
    WidgetTester tester,
  ) async {
    final plugin = PermissionPlusApple();
    final status = await plugin.checkPermission(PermissionType.camera);
    // Just verify we get a valid PermissionStatus back.
    expect(PermissionStatus.values.contains(status), true);
  });
}
