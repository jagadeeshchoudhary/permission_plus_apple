import Contacts

/// Handles contacts permissions via Contacts framework.
///
/// Apple does not distinguish read-only vs write-only contacts access,
/// so `contactsReadOnly` and `contactsWriteOnly` map to the same check.
enum ContactsPermissionHandler {

    static func checkPermission() -> PermissionStatusMessage {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return mapStatus(status)
    }

    static func requestPermission(completion: @escaping (PermissionStatusMessage) -> Void) {
        let currentStatus = checkPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                completion(granted ? .granted : .permanentlyDenied)
            }
        }
    }

    private static func mapStatus(_ status: CNAuthorizationStatus) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
}
