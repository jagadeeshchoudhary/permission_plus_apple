import EventKit

/// Handles calendar and reminder permissions via EventKit.
///
/// On iOS 17+ / macOS 14+, uses the new `requestFullAccessToEvents()` and
/// `requestWriteOnlyAccessToEvents()` APIs. Falls back to the deprecated
/// `requestAccess(to:)` on older versions.
enum EventKitPermissionHandler {

    private static let eventStore = EKEventStore()

    // MARK: - Calendar

    static func checkCalendarPermission(
        for type: PermissionTypeMessage
    ) -> PermissionStatusMessage {
        let status = EKEventStore.authorizationStatus(for: .event)
        return mapCalendarStatus(status, for: type)
    }

    static func requestCalendarPermission(
        for type: PermissionTypeMessage,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = checkCalendarPermission(for: type)
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        if #available(iOS 17, macOS 14, *) {
            if type == .calendarWriteOnly {
                eventStore.requestWriteOnlyAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        let status = self.checkCalendarPermission(for: type)
                        completion(granted ? status : .permanentlyDenied)
                    }
                }
            } else {
                eventStore.requestFullAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted ? .granted : .permanentlyDenied)
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted ? .granted : .permanentlyDenied)
                }
            }
        }
    }

    // MARK: - Reminders

    static func checkReminderPermission() -> PermissionStatusMessage {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        return mapReminderStatus(status)
    }

    static func requestReminderPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = checkReminderPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        if #available(iOS 17, macOS 14, *) {
            eventStore.requestFullAccessToReminders { granted, _ in
                DispatchQueue.main.async {
                    completion(granted ? .granted : .permanentlyDenied)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted ? .granted : .permanentlyDenied)
                }
            }
        }
    }

    // MARK: - Status Mapping

    private static func mapCalendarStatus(
        _ status: EKAuthorizationStatus,
        for type: PermissionTypeMessage
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .permanentlyDenied
        case .authorized, .fullAccess:
            return .granted
        case .writeOnly:
            // Write-only access: "granted" for calendarWriteOnly, "limited" otherwise
            return type == .calendarWriteOnly ? .granted : .limited
        @unknown default:
            return .notDetermined
        }
    }

    private static func mapReminderStatus(
        _ status: EKAuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized, .fullAccess: return .granted
        case .writeOnly: return .limited
        @unknown default: return .notDetermined
        }
    }
}
