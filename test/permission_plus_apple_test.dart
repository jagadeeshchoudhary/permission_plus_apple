import 'package:flutter_test/flutter_test.dart';
import 'package:permission_plus_apple/permission_plus_apple.dart';
import 'package:permission_plus_apple/src/generated/permission_plus_api.g.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

class FakePermissionPlusHostApi implements PermissionPlusHostApi {
  PermissionStatusMessage checkPermissionResult =
      PermissionStatusMessage.granted;
  PermissionStatusMessage requestPermissionResult =
      PermissionStatusMessage.granted;
  List<PermissionStatusMapEntry> requestPermissionsResult = [];
  bool openSettingsResult = true;
  bool shouldShowRationaleResult = false;
  LocationAccuracyMessage getLocationAccuracyResult =
      LocationAccuracyMessage.precise;
  PermissionStatusMessage requestTemporaryPreciseLocationResult =
      PermissionStatusMessage.granted;

  @override
  Future<PermissionStatusMessage> checkPermission(
    PermissionTypeMessage permission,
  ) async {
    return checkPermissionResult;
  }

  @override
  Future<PermissionStatusMessage> requestPermission(
    PermissionTypeMessage permission,
  ) async {
    return requestPermissionResult;
  }

  @override
  Future<List<PermissionStatusMapEntry>> requestPermissions(
    List<PermissionTypeMessage> permissions,
  ) async {
    return requestPermissionsResult;
  }

  @override
  Future<bool> openSettings() async {
    return openSettingsResult;
  }

  @override
  Future<bool> shouldShowRationale(PermissionTypeMessage permission) async {
    return shouldShowRationaleResult;
  }

  @override
  Future<LocationAccuracyMessage> getLocationAccuracy() async {
    return getLocationAccuracyResult;
  }

  @override
  Future<PermissionStatusMessage> requestTemporaryPreciseLocation(
    String purposeKey,
  ) async {
    return requestTemporaryPreciseLocationResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionPlusApple platform;
  late FakePermissionPlusHostApi fakeApi;

  setUp(() {
    fakeApi = FakePermissionPlusHostApi();
    platform = PermissionPlusApple(api: fakeApi);
  });

  test('registerWith sets instance', () {
    PermissionPlusApple.registerWith();
    expect(PermissionPlusPlatform.instance, isA<PermissionPlusApple>());
  });

  test('checkPermission', () async {
    fakeApi.checkPermissionResult = PermissionStatusMessage.denied;
    final result = await platform.checkPermission(PermissionType.camera);
    expect(result, PermissionStatus.denied);
  });

  test('requestPermission', () async {
    fakeApi.requestPermissionResult = PermissionStatusMessage.restricted;
    final result = await platform.requestPermission(PermissionType.microphone);
    expect(result, PermissionStatus.restricted);
  });

  test('requestPermissions', () async {
    fakeApi.requestPermissionsResult = [
      PermissionStatusMapEntry(
        permission: PermissionTypeMessage.camera,
        status: PermissionStatusMessage.granted,
      ),
      PermissionStatusMapEntry(
        permission: PermissionTypeMessage.microphone,
        status: PermissionStatusMessage.denied,
      ),
    ];
    final result = await platform.requestPermissions([
      PermissionType.camera,
      PermissionType.microphone,
    ]);
    expect(result, {
      PermissionType.camera: PermissionStatus.granted,
      PermissionType.microphone: PermissionStatus.denied,
    });
  });

  test('openSettings', () async {
    fakeApi.openSettingsResult = true;
    final result = await platform.openSettings();
    expect(result, isTrue);

    fakeApi.openSettingsResult = false;
    final resultFalse = await platform.openSettings();
    expect(resultFalse, isFalse);
  });

  test('shouldShowRationale', () async {
    fakeApi.shouldShowRationaleResult = false;
    final result = await platform.shouldShowRationale(PermissionType.camera);
    expect(result, isFalse);

    fakeApi.shouldShowRationaleResult = true;
    final resultTrue = await platform.shouldShowRationale(
      PermissionType.camera,
    );
    expect(resultTrue, isTrue);
  });

  test('getLocationAccuracy', () async {
    fakeApi.getLocationAccuracyResult = LocationAccuracyMessage.precise;
    final resultPrecise = await platform.getLocationAccuracy();
    expect(resultPrecise, LocationAccuracy.precise);

    fakeApi.getLocationAccuracyResult = LocationAccuracyMessage.reduced;
    final resultReduced = await platform.getLocationAccuracy();
    expect(resultReduced, LocationAccuracy.reduced);
  });

  test('requestTemporaryPreciseLocation', () async {
    fakeApi.requestTemporaryPreciseLocationResult =
        PermissionStatusMessage.granted;
    final result = await platform.requestTemporaryPreciseLocation(
      purposeKey: 'testKey',
    );
    expect(result, PermissionStatus.granted);
  });

  test('permissionStatusStream throws UnimplementedError', () {
    expect(
      () => platform.permissionStatusStream(PermissionType.camera),
      throwsUnimplementedError,
    );
  });
}
