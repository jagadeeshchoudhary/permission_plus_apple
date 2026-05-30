import Photos

/// Handles photos permissions (photos, photosAddOnly, videos, audio) via Photos framework.
enum PhotosPermissionHandler {

    static func checkPermission(addOnly: Bool) -> PermissionStatusMessage {
        if #available(iOS 14, macOS 11, *) {
            let level: PHAccessLevel = addOnly ? .addOnly : .readWrite
            return mapStatus(PHPhotoLibrary.authorizationStatus(for: level))
        } else {
            return mapStatus(PHPhotoLibrary.authorizationStatus())
        }
    }

    static func requestPermission(
        addOnly: Bool,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        let currentStatus = checkPermission(addOnly: addOnly)
        guard currentStatus == .notDetermined else {
            completion(currentStatus)
            return
        }

        if #available(iOS 14, macOS 11, *) {
            let level: PHAccessLevel = addOnly ? .addOnly : .readWrite
            PHPhotoLibrary.requestAuthorization(for: level) { status in
                DispatchQueue.main.async {
                    completion(self.mapStatus(status))
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(self.mapStatus(status))
                }
            }
        }
    }

    private static func mapStatus(_ status: PHAuthorizationStatus) -> PermissionStatusMessage {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .permanentlyDenied
        case .authorized: return .granted
        case .limited: return .limited
        @unknown default: return .notDetermined
        }
    }
}
