import Foundation

/// The result of a document capture operation, containing the captured image data.
public struct DocumentCaptureResult: Sendable {
  /// The raw image data (e.g. PNG or JPEG encoded).
  public let imageData: Data
  /// The width of the captured image in pixels.
  public let width: Int
  /// The height of the captured image in pixels.
  public let height: Int
  /// The MIME type of the image data (defaults to `"image/png"`).
  public let mimeType: String

  public init(imageData: Data, width: Int, height: Int, mimeType: String = "image/png") {
    self.imageData = imageData
    self.width = width
    self.height = height
    self.mimeType = mimeType
  }
}

/// The result of a selfie capture operation, containing preview image and biometric blobs.
public struct SelfieCaptureResult: Sendable {
  /// The preview image data for display purposes.
  public let previewImageData: Data
  /// The width of the preview image in pixels.
  public let width: Int
  /// The height of the preview image in pixels.
  public let height: Int
  /// The MIME type of the preview image data (defaults to `"image/jpeg"`).
  public let mimeType: String
  /// The encrypted biometric blob for secure transmission.
  public let encryptedBlob: Data
  /// The unencrypted biometric blob for local processing.
  public let unencryptedBlob: Data

  public init(
    previewImageData: Data,
    width: Int,
    height: Int,
    mimeType: String = "image/jpeg",
    encryptedBlob: Data,
    unencryptedBlob: Data
  ) {
    self.previewImageData = previewImageData
    self.width = width
    self.height = height
    self.mimeType = mimeType
    self.encryptedBlob = encryptedBlob
    self.unencryptedBlob = unencryptedBlob
  }
}

/// The outcome of a capture operation, representing success, cancellation, or failure.
public enum CaptureResult: Sendable {
  /// A successful document capture with the resulting image data.
  case document(DocumentCaptureResult)
  /// A successful selfie capture with preview image and biometric blobs.
  case selfie(SelfieCaptureResult)
  /// The capture was cancelled by the user or system.
  case cancelled(reason: String)
  /// The capture failed with a machine-readable code, message, and recoverability flag.
  case failed(code: String, message: String, recoverable: Bool)
}

extension CaptureResult {
  internal func toBridgeResponse() -> (BridgeResponseStatus, [String: JSONValue]?, BridgeErrorPayload?) {
    switch self {
    case .document(let result):
      let data: [String: JSONValue] = [
        "imageBase64": .string(result.imageData.base64EncodedString()),
        "imageWidth": .number(Double(result.width)),
        "imageHeight": .number(Double(result.height)),
        "mimeType": .string(result.mimeType),
      ]
      return (.success, data, nil)

    case .selfie(let result):
      let data: [String: JSONValue] = [
        "imageBase64": .string(result.previewImageData.base64EncodedString()),
        "imageWidth": .number(Double(result.width)),
        "imageHeight": .number(Double(result.height)),
        "mimeType": .string(result.mimeType),
        "encryptedBlobBase64": .string(result.encryptedBlob.base64EncodedString()),
        "unencryptedBlobBase64": .string(result.unencryptedBlob.base64EncodedString()),
      ]
      return (.success, data, nil)

    case .cancelled(let reason):
      let error = BridgeErrorPayload(code: "CANCELLED", message: reason, recoverable: true)
      return (.cancelled, nil, error)

    case .failed(let code, let message, let recoverable):
      let error = BridgeErrorPayload(code: code, message: message, recoverable: recoverable)
      return (.error, nil, error)
    }
  }
}
