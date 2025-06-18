import Foundation
import AVFoundation
import Combine
import Cocoa

/// Handles requesting sensitive permissions and tracking authorization status.
@MainActor
class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published var microphoneAuthorized: Bool = false
    @Published var cameraAuthorized: Bool = false
    @Published var fullDiskAccessGranted: Bool = false

    private init() {}

    /// Request all required permissions on first launch.
    func requestPermissions() {
        requestMicrophoneAccess()
        requestCameraAccess()
        checkFullDiskAccess()
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
