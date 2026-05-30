import CoreBluetooth

/// Handles Bluetooth permissions via CoreBluetooth.
///
/// Checking uses the static `CBCentralManager.authorization` property (iOS 13.1+).
/// Requesting requires creating a `CBCentralManager` instance, which triggers
/// the system permission dialog. The delegate callback signals the result.
class BluetoothPermissionHandler: NSObject, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager?
    private var completion: ((PermissionStatusMessage) -> Void)?

    // MARK: - Check (static)

    static func checkPermission() -> PermissionStatusMessage {
        if #available(iOS 13.1, macOS 10.15, *) {
            return mapAuthorization(CBCentralManager.authorization)
        }
        // Before iOS 13.1, Bluetooth didn't require explicit permission
        return .granted
    }

    // MARK: - Request (instance, asynchronous)

    func requestPermission(completion: @escaping (PermissionStatusMessage) -> Void) {
        let currentStatus = Self.checkPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        self.completion = completion
        // Creating a CBCentralManager triggers the Bluetooth permission dialog
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let completion = completion else { return }

        if #available(iOS 13.1, macOS 10.15, *) {
            let auth = CBCentralManager.authorization
            // Ignore if still not determined (dialog may still be showing)
            guard auth != .notDetermined else { return }

            self.completion = nil
            completion(Self.mapAuthorization(auth))
            self.centralManager = nil
        } else {
            // Fallback: use the central manager state
            self.completion = nil
            switch central.state {
            case .unauthorized:
                completion(.permanentlyDenied)
            case .poweredOn, .poweredOff:
                completion(.granted)
            case .unsupported:
                completion(.restricted)
            default:
                return  // Still initializing (.unknown / .resetting)
            }
            self.centralManager = nil
        }
    }

    // MARK: - Status Mapping

    private static func mapAuthorization(
        _ auth: CBManagerAuthorization
    ) -> PermissionStatusMessage {
        switch auth {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .allowedAlways: return .granted
        @unknown default: return .notDetermined
        }
    }
}
