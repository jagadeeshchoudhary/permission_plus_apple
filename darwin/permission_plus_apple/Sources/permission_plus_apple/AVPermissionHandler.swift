import AVFoundation

/// Handles camera and microphone permissions via AVFoundation.
enum AVPermissionHandler {

    static func checkPermission(for mediaType: AVMediaType) -> PermissionStatusMessage {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        return mapStatus(status)
    }

    static func requestPermission(
        for mediaType: AVMediaType,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = checkPermission(for: mediaType)
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        AVCaptureDevice.requestAccess(for: mediaType) { granted in
            DispatchQueue.main.async {
                completion(granted ? .granted : .permanentlyDenied)
            }
        }
    }

    private static func mapStatus(_ status: AVAuthorizationStatus) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        @unknown default: return .notDetermined
        }
    }
}
