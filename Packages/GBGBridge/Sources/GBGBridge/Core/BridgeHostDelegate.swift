import Foundation

/// Delegate protocol for receiving bridge host lifecycle events.
///
/// Adopt this protocol to observe all incoming messages and to handle
/// requests that have no registered capability handler.
@MainActor
public protocol BridgeHostDelegate: AnyObject {
  /// Called when the host receives any message from the web layer.
  ///
  /// - Parameters:
  ///   - host: The bridge host that received the message.
  ///   - message: The decoded bridge message.
  func bridgeHost(_ host: BridgeHost, didReceive message: BridgeMessage)

  /// Called when a request arrives that has no registered capability handler.
  ///
  /// - Parameters:
  ///   - host: The bridge host that received the request.
  ///   - message: The unhandled request message.
  func bridgeHost(_ host: BridgeHost, unhandledRequest message: BridgeMessage)
}

extension BridgeHostDelegate {
  public func bridgeHost(_ host: BridgeHost, didReceive message: BridgeMessage) {}
  public func bridgeHost(_ host: BridgeHost, unhandledRequest message: BridgeMessage) {}
}
