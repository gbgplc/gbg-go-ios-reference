import Combine
import Foundation

/// A typed capability slot that manages a single capture workflow (document or selfie).
///
/// `CaptureCapability` bridges between an incoming web request and a native capture UI.
/// Assign a ``handler`` closure to enable the capability, then use ``awaitCompletion()``
/// and ``complete(_:)`` to integrate with SwiftUI presentation flows.
///
/// This class is `@MainActor`-isolated and conforms to `ObservableObject` for SwiftUI binding.
@MainActor
public class CaptureCapability: ObservableObject {
  /// The capability identifier (e.g. `"camera.document"`, `"camera.selfie"`).
  public let id: String
  /// The action identifier that triggers this capability (e.g. `"camera.document.capture"`).
  public let actionId: String

  /// Whether this capability is enabled. Set to `false` to temporarily disable it
  /// without removing the handler.
  @Published public var isEnabled: Bool = true
  /// The currently active request being processed, or `nil` if idle.
  @Published public var activeRequest: BridgeMessage?

  /// The capture handler closure. Setting this triggers `objectWillChange` so that
  /// SwiftUI views depending on `isSupported` update automatically.
  public var handler: (@Sendable (BridgeMessage) async -> CaptureResult)? {
    didSet { objectWillChange.send() }
  }

  /// Whether this capability is currently supported (has a handler and is enabled).
  public var isSupported: Bool {
    handler != nil && isEnabled
  }

  /// The current permission state for the underlying hardware (camera, NFC, etc.).
  /// Setting this triggers `objectWillChange` so that UI reflecting permission state updates.
  @Published public var permissionState: PermissionState = .notDetermined

  /// Optional semver version string for this capability.
  public var version: String?

  // Continuation for the SwiftUI bridge pattern: handler suspends via
  // awaitCompletion(), view layer resumes via complete().
  private var pendingContinuation: CheckedContinuation<CaptureResult, Never>?

  /// Creates a capture capability slot.
  ///
  /// - Parameters:
  ///   - id: The capability identifier.
  ///   - actionId: The action identifier that triggers this capability.
  ///   - version: Optional version string.
  public init(id: String, actionId: String, version: String? = nil) {
    self.id = id
    self.actionId = actionId
    self.version = version
  }

  /// Builds a ``BridgeCapabilityInfo`` snapshot describing the current state of this slot.
  ///
  /// - Returns: A capability info value suitable for inclusion in a `capability.query` response.
  public func buildCapabilityInfo() -> BridgeCapabilityInfo {
    BridgeCapabilityInfo(
      supported: isSupported,
      version: isSupported ? (version ?? "1.0") : nil,
      constraints: nil,
      permissionState: permissionState.rawValue
    )
  }

  /// Suspends the current handler until ``complete(_:)`` is called.
  ///
  /// Use this in handlers that drive UI presentation (e.g. SwiftUI `fullScreenCover`)
  /// rather than imperative capture APIs.
  ///
  /// - Returns: The capture result provided by the view layer via ``complete(_:)``.
  public func awaitCompletion() async -> CaptureResult {
    await withCheckedContinuation { continuation in
      self.pendingContinuation = continuation
    }
  }

  /// Resumes the pending handler with a result.
  ///
  /// Call from view-layer code (e.g. camera callback closures) to complete the capture flow.
  ///
  /// - Parameter result: The capture outcome to deliver to the waiting handler.
  public func complete(_ result: CaptureResult) {
    pendingContinuation?.resume(returning: result)
    pendingContinuation = nil
    // Note: activeRequest is cleared by handleRequest's Task after this returns.
    // We do NOT clear it here to avoid a race with the Task's cleanup.
  }

  /// Cancels the in-flight request if one exists. Safe to call even when idle.
  ///
  /// This resumes the pending continuation with `.cancelled` and clears ``activeRequest``.
  /// Call this from dismiss handlers, `onDisappear`, or any teardown path to prevent
  /// a leaked `CheckedContinuation`.
  ///
  /// - Parameter reason: A human-readable cancellation reason.
  public func cancelIfBusy(reason: String = "Request cancelled") {
    if pendingContinuation != nil {
      pendingContinuation?.resume(returning: .cancelled(reason: reason))
      pendingContinuation = nil
    }
    activeRequest = nil
  }

  internal func handleRequest(_ request: BridgeMessage, responder: BridgeResponder) {
    guard let handler else {
      responder.respond(
        status: .unsupported,
        data: nil,
        error: BridgeErrorPayload(
          code: "UNSUPPORTED",
          message: "No handler registered for \(actionId)",
          recoverable: false
        )
      )
      return
    }

    if activeRequest != nil {
      responder.respond(
        status: .error,
        data: nil,
        error: BridgeErrorPayload(
          code: "BUSY",
          message: "A \(id) capture request is already in progress",
          recoverable: true
        )
      )
      return
    }

    activeRequest = request
    let captureHandler = handler

    Task {
      let result: CaptureResult
      if Task.isCancelled {
        result = .cancelled(reason: "Task cancelled")
      } else {
        result = await captureHandler(request)
      }
      let (status, data, error) = result.toBridgeResponse()
      responder.respond(status: status, data: data, error: error)
      self.activeRequest = nil
    }
  }
}
