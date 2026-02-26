import AVFoundation

/// Utility for checking camera hardware availability and permission status.
public struct CameraDetector {
  /// The result of a camera availability check.
  public struct Result: Sendable {
    /// Whether a video capture device is physically available on this device.
    public let hardwareAvailable: Bool
    /// The current camera permission state.
    public let permissionState: PermissionState
  }

  /// Checks camera hardware availability and the current permission state.
  ///
  /// - Returns: A ``Result`` containing hardware availability and permission status.
  public static func check() -> Result {
    let hardwareAvailable = AVCaptureDevice.default(for: .video) != nil

    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let permissionState: PermissionState
    switch authStatus {
    case .authorized:
      permissionState = .granted
    case .denied:
      permissionState = .denied
    case .notDetermined:
      permissionState = .notDetermined
    case .restricted:
      permissionState = .restricted
    @unknown default:
      permissionState = .notDetermined
    }

    return Result(hardwareAvailable: hardwareAvailable, permissionState: permissionState)
  }
}
