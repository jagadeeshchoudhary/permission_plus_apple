import Speech

#if os(iOS)
import CoreMotion
import MediaPlayer
import AppTrackingTransparency
#endif

// MARK: - Speech Recognition

/// Handles speech recognition permissions via Speech framework.
enum SpeechPermissionHandler {

    static func checkPermission() -> PermissionStatusMessage {
        let status = SFSpeechRecognizer.authorizationStatus()
        return mapStatus(status)
    }

    static func requestPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = checkPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(self.mapStatus(status))
            }
        }
    }

    private static func mapStatus(
        _ status: SFSpeechRecognizerAuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
}

// MARK: - Motion / Sensors (iOS only)

/// Handles motion sensor permissions via CoreMotion.
///
/// `CMMotionActivityManager` is only available on iOS.
/// On macOS, all methods return `.restricted`.
enum SensorsPermissionHandler {

    static func checkPermission() -> PermissionStatusMessage {
        #if os(iOS)
        let status = CMMotionActivityManager.authorizationStatus()
        return mapStatus(status)
        #else
        return .restricted
        #endif
    }

    static func requestPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        #if os(iOS)
        let currentStatus = checkPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        // Triggering an activity query prompts the permission dialog
        let manager = CMMotionActivityManager()
        let now = Date()
        manager.queryActivityStarting(from: now, to: now, to: .main) { _, _ in
            manager.stopActivityUpdates()
            DispatchQueue.main.async {
                completion(self.checkPermission())
            }
        }
        #else
        completion(.restricted)
        #endif
    }

    #if os(iOS)
    private static func mapStatus(
        _ status: CMAuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
    #endif
}

// MARK: - Media Library (iOS only)

/// Handles media library permissions via MediaPlayer.
///
/// `MPMediaLibrary` is only available on iOS.
/// On macOS, all methods return `.restricted`.
enum MediaLibraryPermissionHandler {

    static func checkPermission() -> PermissionStatusMessage {
        #if os(iOS)
        let status = MPMediaLibrary.authorizationStatus()
        return mapStatus(status)
        #else
        return .restricted
        #endif
    }

    static func requestPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        #if os(iOS)
        let currentStatus = checkPermission()
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(self.mapStatus(status))
            }
        }
        #else
        completion(.restricted)
        #endif
    }

    #if os(iOS)
    private static func mapStatus(
        _ status: MPMediaLibraryAuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
    #endif
}

// MARK: - App Tracking Transparency (iOS 14+ only)

/// Handles App Tracking Transparency permissions.
///
/// `ATTrackingManager` is only available on iOS 14+.
/// On macOS or iOS < 14, all methods return `.restricted`.
enum TrackingPermissionHandler {

    static func checkPermission() -> PermissionStatusMessage {
        #if os(iOS)
        if #available(iOS 14, *) {
            return mapStatus(ATTrackingManager.trackingAuthorizationStatus)
        }
        return .restricted
        #else
        return .restricted
        #endif
    }

    static func requestPermission(
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        #if os(iOS)
        if #available(iOS 14, *) {
            let currentStatus = checkPermission()
            guard currentStatus == .notDetermined else {
                completion(currentStatus)
                return
            }

            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    completion(self.mapStatus(status))
                }
            }
        } else {
            completion(.restricted)
        }
        #else
        completion(.restricted)
        #endif
    }

    #if os(iOS)
    @available(iOS 14, *)
    private static func mapStatus(
        _ status: ATTrackingManager.AuthorizationStatus
    ) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
    #endif
}
