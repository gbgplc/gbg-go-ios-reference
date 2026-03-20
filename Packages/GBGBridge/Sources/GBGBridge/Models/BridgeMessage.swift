import Foundation

/// The type of a bridge message, indicating its role in the request/response lifecycle.
public enum BridgeMessageType: String, Codable, Sendable {
  /// A request from the web layer expecting a response.
  case request
  /// A response to a previously received request.
  case response
  /// A one-way notification that does not expect a response.
  case event
}

/// The outcome status of a bridge response.
public enum BridgeResponseStatus: String, Codable, Sendable {
  /// The request completed successfully.
  case success
  /// The request failed with an error.
  case error
  /// The request was cancelled before completion.
  case cancelled
  /// The requested capability is not supported by the host.
  case unsupported
  /// The request was received and acknowledged without a full result.
  case acknowledged
}

/// A single message exchanged between the web layer and the native host.
public struct BridgeMessage: Codable, Identifiable, Sendable {
  /// The bridge protocol version (e.g. `"1.0"`).
  public let version: String
  /// A unique identifier used to correlate requests with their responses.
  public let correlationId: String
  /// The message type (request, response, or event).
  public let type: BridgeMessageType
  /// Unix timestamp in milliseconds when the message was created.
  public let timestamp: TimeInterval
  /// The message payload containing the action, data, and optional status/error.
  public let payload: BridgePayload

  public init(
    version: String,
    correlationId: String,
    type: BridgeMessageType,
    timestamp: TimeInterval,
    payload: BridgePayload
  ) {
    self.version = version
    self.correlationId = correlationId
    self.type = type
    self.timestamp = timestamp
    self.payload = payload
  }

  public var id: String {
    "\(correlationId)-\(timestamp)-\(type.rawValue)"
  }
}

/// Options that may accompany a request payload.
public struct BridgeRequestOptions: Codable, Sendable {
  /// Request timeout in milliseconds.
  public let timeout: Double?
  /// Whether the host can decline in favour of a web fallback.
  public let fallbackAllowed: Bool?

  public init(timeout: Double? = nil, fallbackAllowed: Bool? = nil) {
    self.timeout = timeout
    self.fallbackAllowed = fallbackAllowed
  }
}

/// The payload of a bridge message, carrying the action and associated data.
public struct BridgePayload: Codable, Sendable {
  /// The action identifier (e.g. `"camera.document.capture"`, `"capability.query"`).
  public let action: String
  /// Optional JSON-compatible data associated with the message.
  public let data: [String: JSONValue]?
  /// The response status, present only in response messages.
  public let status: BridgeResponseStatus?
  /// A structured error payload, present only when status is `.error` or `.cancelled`.
  public let error: BridgeErrorPayload?
  /// Optional request options (present only in request messages).
  public let options: BridgeRequestOptions?

  public init(
    action: String,
    data: [String: JSONValue]?,
    status: BridgeResponseStatus?,
    error: BridgeErrorPayload?,
    options: BridgeRequestOptions? = nil
  ) {
    self.action = action
    self.data = data
    self.status = status
    self.error = error
    self.options = options
  }
}

/// A structured error included in bridge response payloads.
public struct BridgeErrorPayload: Codable, Sendable {
  /// A machine-readable error code (e.g. `"CANCELLED"`, `"BUSY"`).
  public let code: String
  /// A human-readable description of the error.
  public let message: String
  /// Whether the error is recoverable and the operation can be retried.
  public let recoverable: Bool

  public init(code: String, message: String, recoverable: Bool) {
    self.code = code
    self.message = message
    self.recoverable = recoverable
  }
}
