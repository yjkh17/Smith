import Foundation
import AVFoundation
import Combine
import Cocoa
import CoreLocation

/// Handles requesting sensitive permissions and tracking authorization status.
@MainActor
class PermissionsManager: NSObject, ObservableObject {
    static let shared = PermissionsManager()

    @Published var microphoneAuthorized: Bool = false
    @Published var cameraAuthorized: Bool = false
    @Published var fullDiskAccessGranted: Bool = false
    @Published var locationAuthorized: Bool = false

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    /// Request all required permissions on first launch.
    func requestPermissions() {
        requestMicrophoneAccess()
        requestCameraAccess()
        checkFullDiskAccess()
        requestLocationAccess()
    }

    private func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                self.microphoneAuthorized = granted
                if !granted {
                    print("Microphone permission denied - disabling audio features")
                }
            }
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                self.cameraAuthorized = granted
                if !granted {
                    print("Camera permission denied - disabling camera features")
                }
            }
        }
    }

    func requestLocationAccess() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            updateLocationAuthorization(status: status)
        }
    }

    /// There is no direct API for Full Disk Access. This method attempts to read
    /// a protected location to infer whether access has been granted.
    private func checkFullDiskAccess() {
        let fm = FileManager.default
        let path = "/Library" // A location requiring full disk access on modern macOS
        let canRead = fm.isReadableFile(atPath: path)
        fullDiskAccessGranted = canRead
        if !canRead {
            print("Full Disk Access not granted - certain monitoring features disabled")
        }
    }
}

extension PermissionsManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            updateLocationAuthorization(status: status)
        }
    }

    private func updateLocationAuthorization(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationAuthorized = true
        default:
            locationAuthorized = false
            if status != .notDetermined {
                print("Location permission denied - disabling location features")
            }
        }
    }
}
