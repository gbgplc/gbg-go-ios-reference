import SwiftUI
import UIKit

/// A stub document capture view for development and early integration.
///
/// On a real device this presents `UIImagePickerController` with the rear camera.
/// On the iOS Simulator — where camera hardware is unavailable — it automatically
/// shows a static placeholder document image with a shutter-style capture button,
/// so you can exercise the full bridge flow without a physical device.
///
/// Replace this view with the real SmartCapture document SDK view before shipping
/// to production.
///
/// - Important: This view captures a standard photo. It does **not** perform
///   document detection, auto-cropping, quality checks, or any of the processing
///   that the SmartCapture document SDK provides.
///
/// ## Usage
///
/// ```swift
/// StubDocumentCameraView(
///     onCaptured: { result in
///         host.documentCapture.complete(.document(result))
///     },
///     onCancelled: {
///         host.documentCapture.complete(.cancelled(reason: "User dismissed"))
///     }
/// )
/// ```
public struct StubDocumentCameraView: View {
  private let onCaptured: (DocumentCaptureResult) -> Void
  private let onCancelled: () -> Void

  /// Creates a stub document camera view.
  ///
  /// - Parameters:
  ///   - onCaptured: Called with a `DocumentCaptureResult` when the user takes or selects a photo.
  ///   - onCancelled: Called when the user dismisses the picker without selecting a photo.
  public init(
    onCaptured: @escaping (DocumentCaptureResult) -> Void,
    onCancelled: @escaping () -> Void
  ) {
    self.onCaptured = onCaptured
    self.onCancelled = onCancelled
  }

  public var body: some View {
    #if targetEnvironment(simulator)
    SimulatorDocumentCaptureView(
      onCaptured: onCaptured,
      onCancelled: onCancelled
    )
    #else
    StubImagePicker(
      sourceType: UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary,
      cameraDevice: .rear,
      onPicked: { image in
        guard let result = Self.makeResult(from: image) else {
          onCancelled()
          return
        }
        onCaptured(result)
      },
      onCancelled: onCancelled
    )
    #endif
  }

  private static func makeResult(from image: UIImage) -> DocumentCaptureResult? {
    guard let pngData = image.pngData() else { return nil }
    return DocumentCaptureResult(
      imageData: pngData,
      width: Int(image.size.width * image.scale),
      height: Int(image.size.height * image.scale),
      mimeType: "image/png"
    )
  }
}
