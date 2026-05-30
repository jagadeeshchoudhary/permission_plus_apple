import CoreLocation

/// Handles location permissions, accuracy checks, and temporary precise location requests.
///
/// Uses CLLocationManagerDelegate for async permission request callbacks.
/// Check methods are static/synchronous; request methods require an instance.
class LocationPermissionHandler: NSObject, CLLocationManagerDelegate {

    private var locationManager: CLLocationManager?
    private var permissionCompletion: ((PermissionStatusMessage) -> Void)?
    private var requestedType: PermissionTypeMessage?

    // MARK: - Check (static, synchronous)

    static func checkPermission(for type: PermissionTypeMessage) -> PermissionStatusMessage {
        let status: CLAuthorizationStatus
        if #available(iOS 14, macOS 11, *) {
            status = CLLocationManager().authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        return mapStatus(status, for: type)
    }

    static func getLocationAccuracy() -> LocationAccuracyMessage {
        if #available(iOS 14, macOS 11, *) {
            let manager = CLLocationManager()
            switch manager.accuracyAuthorization {
            case .fullAccuracy:
                return .precise
            case .reducedAccuracy:
                return .reduced
            @unknown default:
                return .precise
            }
        }
        // Before iOS 14 / macOS 11, reduced accuracy didn't exist
        return .precise
    }

    // MARK: - Request Permission (instance, asynchronous)

    func requestPermission(
        for type: PermissionTypeMessage,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = Self.checkPermission(for: type)
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        self.requestedType = type
        self.permissionCompletion = completion
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self

        switch type {
        case .locationAlways:
            self.locationManager?.requestAlwaysAuthorization()
        default:
            self.locationManager?.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Temporary Precise Location

    func requestTemporaryPreciseLocation(
        purposeKey: String,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        if #available(iOS 14, macOS 11, *) {
            let manager = CLLocationManager()
            self.locationManager = manager  // Retain while waiting
            manager.requestTemporaryFullAccuracyAuthorization(
                withPurposeKey: purposeKey
            ) { error in
                DispatchQueue.main.async {
                    let status = Self.checkPermission(for: .locationWhenInUse)
                    completion(status)
                    self.locationManager = nil
                }
            }
        } else {
            // Before iOS 14, no concept of temporary precise location
            completion(Self.checkPermission(for: .locationWhenInUse))
        }
    }

    // MARK: - CLLocationManagerDelegate

    /// iOS 14+, macOS 11+
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange(manager)
    }

    /// iOS 13, macOS 10.15 (deprecated in iOS 14, but still called on older OS)
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        handleAuthorizationChange(manager)
    }

    private func handleAuthorizationChange(_ manager: CLLocationManager) {
        guard let completion = permissionCompletion,
              let type = requestedType else { return }

        let status: CLAuthorizationStatus
        if #available(iOS 14, macOS 11, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        // Ignore the initial delegate callback while still .notDetermined
        // (the system hasn't shown the dialog yet)
        guard status != .notDetermined else { return }

        self.permissionCompletion = nil
        self.requestedType = nil
        self.locationManager?.delegate = nil
        self.locationManager = nil
        completion(Self.mapStatus(status, for: type))
    }

    // MARK: - Status Mapping

    private static func mapStatus(
        _ status: CLAuthorizationStatus,
        for type: PermissionTypeMessage
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .permanentlyDenied
        case .authorizedWhenInUse:
            // When-in-use is insufficient for "always" requests
            return type == .locationAlways ? .denied : .granted
        case .authorizedAlways:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }
}
