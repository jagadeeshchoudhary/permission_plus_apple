import UserNotifications

/// Handles notification and critical alert permissions via UserNotifications.
enum NotificationPermissionHandler {

    // MARK: - Notification

    static func checkPermission(completion: @escaping (PermissionStatusMessage) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(mapStatus(settings.authorizationStatus))
            }
        }
    }

    static func requestPermission(completion: @escaping (PermissionStatusMessage) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    completion(.granted)
                } else {
                    // Re-check to distinguish denied vs permanentlyDenied
                    self.checkPermission { status in
                        completion(status)
                    }
                }
            }
        }
    }

    // MARK: - Critical Alerts

    static func checkCriticalAlertsPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.criticalAlertSetting {
                case .enabled:
                    completion(.granted)
                case .disabled:
                    // Check if notifications are authorized at all
                    if settings.authorizationStatus == .notDetermined {
                        completion(.notDetermined)
                    } else {
                        completion(.permanentlyDenied)
                    }
                case .notSupported:
                    completion(.restricted)
                @unknown default:
                    completion(.notDetermined)
                }
            }
        }
    }

    static func requestCriticalAlertsPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.criticalAlert]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted ? .granted : .permanentlyDenied)
            }
        }
    }

    // MARK: - Status Mapping

    private static func mapStatus(
        _ status: UNAuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        case .provisional: return .provisional
        case .ephemeral: return .granted
        @unknown default: return .notDetermined
        }
    }
}
