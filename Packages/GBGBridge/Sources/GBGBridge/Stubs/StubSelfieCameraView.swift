import SwiftUI
import UIKit

/// A stub selfie capture view that uses `UIImagePickerController` with the front camera
/// to take a photo or select from the photo library.
///
/// Use this view during development and early integration to prove the bridge works
/// end-to-end without requiring the face liveness SDK. Replace it with the real
/// SDK-backed view before shipping to production.
///
/// - Important: This view captures a standard selfie. It does **not** perform
///   liveness detection, face mesh analysis, or biometric encryption. The
///   `encryptedBlob` and `unencryptedBlob` fields in the returned
///   `SelfieCaptureResult` contain the raw JPEG image data as a placeholder.
///   These blobs will **not** pass server-side liveness validation.
///
/// ## Usage
///
/// ```swift
/// StubSelfieCameraView(
///     onCaptured: { result in
///         host.selfieCapture.complete(.selfie(result))
///     },
///     onCancelled: {
///         host.selfieCapture.complete(.cancelled(reason: "User dismissed"))
///     }
/// )
/// ```
public struct StubSelfieCameraView: View {
  private let onCaptured: (SelfieCaptureResult) -> Void
  private let onCancelled: () -> Void

  /// Creates a stub selfie camera view.
  ///
  /// - Parameters:
  ///   - onCaptured: Called with a `SelfieCaptureResult` when the user takes or selects a photo.
  ///     The `encryptedBlob` and `unencryptedBlob` fields will contain the raw JPEG data
  ///     as a placeholder — not real biometric data.
  ///   - onCancelled: Called when the user dismisses the picker without selecting a photo.
  public init(
    onCaptured: @escaping (SelfieCaptureResult) -> Void,
    onCancelled: @escaping () -> Void
  ) {
    self.onCaptured = onCaptured
    self.onCancelled = onCancelled
  }

  public var body: some View {
    StubImagePicker(
      sourceType: UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary,
      cameraDevice: .front,
      onPicked: { image in
        guard let result = Self.makeResult(from: image) else {
          onCancelled()
          return
        }
        onCaptured(result)
      },
      onCancelled: onCancelled
    )
  }

  private static func makeResult(from image: UIImage) -> SelfieCaptureResult? {
    guard let jpegData = image.jpegData(compressionQuality: 0.85) else { return nil }
    return SelfieCaptureResult(
      previewImageData: jpegData,
      width: Int(image.size.width * image.scale),
      height: Int(image.size.height * image.scale),
      mimeType: "image/jpeg",
      encryptedBlob: jpegData,
      unencryptedBlob: jpegData
    )
  }
}
