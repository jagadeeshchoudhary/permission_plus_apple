// Import the correct Flutter module and UI framework for each platform
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif

public class PermissionPlusApplePlugin: NSObject, FlutterPlugin, PermissionPlusHostApi {

    // Stateful handlers (maintain references for delegate callbacks)
    private var locationHandler: LocationPermissionHandler?
    private var bluetoothHandler: BluetoothPermissionHandler?

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let instance = PermissionPlusApplePlugin()
        PermissionPlusHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
    }

    // MARK: - PermissionPlusHostApi

    func checkPermission(
        permission: PermissionTypeMessage,
        completion: @escaping (Result<PermissionStatusMessage, Error>) -> Void
    ) {
        checkPermissionStatus(permission) { status in
            completion(.success(status))
        }
    }

    func requestPermission(
        permission: PermissionTypeMessage,
        completion: @escaping (Result<PermissionStatusMessage, Error>) -> Void
    ) {
        requestPermissionForType(permission) { status in
            completion(.success(status))
        }
    }

    func requestPermissions(
        permissions: [PermissionTypeMessage],
        completion: @escaping (Result<[PermissionStatusMapEntry], Error>) -> Void
    ) {
        var entries: [PermissionStatusMapEntry] = []
        var remaining = permissions

        // Request permissions sequentially to avoid overlapping dialogs
        func requestNext() {
            guard !remaining.isEmpty else {
                completion(.success(entries))
                return
            }
            let permission = remaining.removeFirst()
            requestPermissionForType(permission) { status in
                entries.append(PermissionStatusMapEntry(
                    permission: permission,
                    status: status
                ))
                requestNext()
            }
        }

        requestNext()
    }

    func openSettings(
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            completion(.success(false))
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            completion(.success(success))
        }
        #elseif os(macOS)
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ) {
            let success = NSWorkspace.shared.open(url)
            completion(.success(success))
        } else {
            completion(.success(false))
        }
        #endif
    }

    func shouldShowRationale(
        permission: PermissionTypeMessage,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        // Apple platforms do not have a "show rationale" concept
        completion(.success(false))
    }

    func getLocationAccuracy(
        completion: @escaping (Result<LocationAccuracyMessage, Error>) -> Void
    ) {
        let accuracy = LocationPermissionHandler.getLocationAccuracy()
        completion(.success(accuracy))
    }

    func requestTemporaryPreciseLocation(
        purposeKey: String,
        completion: @escaping (Result<PermissionStatusMessage, Error>) -> Void
    ) {
        let handler = getLocationHandler()
        handler.requestTemporaryPreciseLocation(purposeKey: purposeKey) { status in
            completion(.success(status))
        }
    }

    // MARK: - Private Routing

    /// Routes a check-permission call to the appropriate handler.
    ///
    /// Most checks are synchronous, but notification checks are async
    /// (requires `UNUserNotificationCenter.getNotificationSettings`).
    private func checkPermissionStatus(
        _ permission: PermissionTypeMessage,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        switch permission {
        // AVFoundation
        case .camera:
            completion(AVPermissionHandler.checkPermission(for: .video))
        case .microphone:
            completion(AVPermissionHandler.checkPermission(for: .audio))

        // Photos
        case .photos, .videos, .audio:
            completion(PhotosPermissionHandler.checkPermission(addOnly: false))
        case .photosAddOnly:
            completion(PhotosPermissionHandler.checkPermission(addOnly: true))

        // Location
        case .location, .locationWhenInUse:
            completion(LocationPermissionHandler.checkPermission(for: .locationWhenInUse))
        case .locationAlways:
            completion(LocationPermissionHandler.checkPermission(for: .locationAlways))

        // Notifications (async check)
        case .notification:
            NotificationPermissionHandler.checkPermission { status in
                completion(status)
            }
        case .criticalAlerts:
            NotificationPermissionHandler.checkCriticalAlertsPermission { status in
                completion(status)
            }

        // Contacts
        case .contacts, .contactsReadOnly, .contactsWriteOnly:
            completion(ContactsPermissionHandler.checkPermission())

        // Calendar & Reminders
        case .calendar, .calendarReadOnly, .calendarWriteOnly:
            completion(EventKitPermissionHandler.checkCalendarPermission(for: permission))
        case .reminders:
            completion(EventKitPermissionHandler.checkReminderPermission())

        // Storage (not applicable on Apple — apps have sandboxed access)
        case .storage, .storageReadOnly, .storageWriteOnly:
            completion(.granted)

        // Bluetooth
        case .bluetooth:
            completion(BluetoothPermissionHandler.checkPermission())

        // Speech
        case .speech:
            completion(SpeechPermissionHandler.checkPermission())

        // Media Library (iOS only)
        case .mediaLibrary:
            completion(MediaLibraryPermissionHandler.checkPermission())

        // Sensors / Motion (iOS only)
        case .sensors:
            completion(SensorsPermissionHandler.checkPermission())

        // Phone & SMS (Android only — not applicable on Apple)
        case .phone, .sms:
            completion(.granted)

        // App Tracking Transparency (iOS 14+ only)
        case .appTrackingTransparency:
            completion(TrackingPermissionHandler.checkPermission())
        }
    }

    /// Routes a request-permission call to the appropriate handler.
    private func requestPermissionForType(
        _ permission: PermissionTypeMessage,
        completion: @escaping (PermissionStatusMessage) -> Void
    ) {
        switch permission {
        // AVFoundation
        case .camera:
            AVPermissionHandler.requestPermission(for: .video, completion: completion)
        case .microphone:
            AVPermissionHandler.requestPermission(for: .audio, completion: completion)

        // Photos
        case .photos, .videos, .audio:
            PhotosPermissionHandler.requestPermission(addOnly: false, completion: completion)
        case .photosAddOnly:
            PhotosPermissionHandler.requestPermission(addOnly: true, completion: completion)

        // Location
        case .location, .locationWhenInUse:
            let handler = getLocationHandler()
            handler.requestPermission(for: .locationWhenInUse, completion: completion)
        case .locationAlways:
            let handler = getLocationHandler()
            handler.requestPermission(for: .locationAlways, completion: completion)

        // Notifications
        case .notification:
            NotificationPermissionHandler.requestPermission(completion: completion)
        case .criticalAlerts:
            NotificationPermissionHandler.requestCriticalAlertsPermission(completion: completion)

        // Contacts
        case .contacts, .contactsReadOnly, .contactsWriteOnly:
            ContactsPermissionHandler.requestPermission(completion: completion)

        // Calendar & Reminders
        case .calendar, .calendarReadOnly:
            EventKitPermissionHandler.requestCalendarPermission(for: permission, completion: completion)
        case .calendarWriteOnly:
            EventKitPermissionHandler.requestCalendarPermission(for: .calendarWriteOnly, completion: completion)
        case .reminders:
            EventKitPermissionHandler.requestReminderPermission(completion: completion)

        // Storage (not applicable on Apple)
        case .storage, .storageReadOnly, .storageWriteOnly:
            completion(.granted)

        // Bluetooth
        case .bluetooth:
            let handler = getBluetoothHandler()
            handler.requestPermission(completion: completion)

        // Speech
        case .speech:
            SpeechPermissionHandler.requestPermission(completion: completion)

        // Media Library (iOS only)
        case .mediaLibrary:
            MediaLibraryPermissionHandler.requestPermission(completion: completion)

        // Sensors / Motion (iOS only)
        case .sensors:
            SensorsPermissionHandler.requestPermission(completion: completion)

        // Phone & SMS (Android only)
        case .phone, .sms:
            completion(.granted)

        // App Tracking Transparency (iOS 14+ only)
        case .appTrackingTransparency:
            TrackingPermissionHandler.requestPermission(completion: completion)
        }
    }

    // MARK: - Handler Lifecycle

    private func getLocationHandler() -> LocationPermissionHandler {
        if locationHandler == nil {
            locationHandler = LocationPermissionHandler()
        }
        return locationHandler!
    }

    private func getBluetoothHandler() -> BluetoothPermissionHandler {
        if bluetoothHandler == nil {
            bluetoothHandler = BluetoothPermissionHandler()
        }
        return bluetoothHandler!
    }
}
