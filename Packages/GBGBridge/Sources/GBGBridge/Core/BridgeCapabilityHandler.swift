import Foundation

/// A type that can send a response back to the web layer on behalf of a capability handler.
///
/// Implementations are provided internally by `BridgeHost`; capability handlers receive
/// a responder and call ``respond(status:data:error:)`` to complete the request.
public protocol BridgeResponder: Sendable {
  /// Sends a response for the current request.
  ///
  /// - Parameters:
  ///   - status: The response status (e.g. `.success`, `.error`).
  ///   - data: Optional JSON-compatible response data.
  ///   - error: Optional structured error payload.
  func respond(status: BridgeResponseStatus, data: [String: JSONValue]?, error: BridgeErrorPayload?)
}

/// A handler that processes bridge requests for a specific action.
///
/// Conform to this protocol to implement a native capability that the web layer can invoke.
/// Handlers are called on a cooperative thread pool; use `@MainActor` for any UI work.
///
/// Register handlers via ``BridgeHost/register(handler:)``.
public protocol BridgeCapabilityHandler: AnyObject, Sendable {
  /// The action identifier this handler responds to (e.g. `"camera.document.capture"`).
  var action: String { get }

  /// Processes an incoming bridge request.
  ///
  /// Called on a cooperative thread pool. Use `@MainActor` if the implementation
  /// needs to interact with UIKit or SwiftUI APIs.
  ///
  /// - Parameters:
  ///   - request: The incoming bridge message.
  ///   - responder: The responder to send a result back to the web layer.
  func handle(request: BridgeMessage, responder: BridgeResponder) async
}
