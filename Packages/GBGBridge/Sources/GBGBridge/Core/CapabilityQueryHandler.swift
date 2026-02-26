import Foundation

/// Built-in handler for the `capability.query` action.
///
/// This handler is registered automatically by ``BridgeHost`` and responds to
/// `capability.query` requests with the current set of supported capabilities,
/// the host environment (`"ios"`), and the host version string.
public final class CapabilityQueryHandler: BridgeCapabilityHandler, @unchecked Sendable {
  public let action = "capability.query"

  private let richProvider: (() -> [String: BridgeCapabilityInfo])?
  private let simpleProvider: (() -> [String: Bool])?
  private let hostVersion: String

  /// Creates a query handler backed by a simple `Bool` capability map.
  ///
  /// - Parameters:
  ///   - capabilities: A closure returning the current capability map.
  ///   - hostVersion: The host application version string.
  public init(capabilities: @escaping () -> [String: Bool], hostVersion: String) {
    self.simpleProvider = capabilities
    self.richProvider = nil
    self.hostVersion = hostVersion
  }

  /// Creates a query handler backed by a rich ``BridgeCapabilityInfo`` map.
  ///
  /// - Parameters:
  ///   - richCapabilities: A closure returning the current rich capability map.
  ///   - hostVersion: The host application version string.
  public init(richCapabilities: @escaping () -> [String: BridgeCapabilityInfo], hostVersion: String) {
    self.richProvider = richCapabilities
    self.simpleProvider = nil
    self.hostVersion = hostVersion
  }

  public func handle(request: BridgeMessage, responder: BridgeResponder) async {
    let capabilitiesPayload: [String: JSONValue]

    if let richProvider {
      let capabilities = await MainActor.run { richProvider() }
      capabilitiesPayload = capabilities.reduce(into: [String: JSONValue]()) { result, entry in
        let (id, info) = entry
        var capObj: [String: JSONValue] = [
          "supported": .bool(info.supported),
          "version": info.version.map { .string($0) } ?? .null,
        ]
        if let permissionState = info.permissionState {
          capObj["permissionState"] = .string(permissionState)
        }
        result[id] = .object(capObj)
      }
    } else if let simpleProvider {
      let capabilities = await MainActor.run { simpleProvider() }
      capabilitiesPayload = capabilities.reduce(into: [String: JSONValue]()) { result, entry in
        let (id, enabled) = entry
        result[id] = .object([
          "supported": .bool(enabled),
          "version": enabled ? .string("1.0") : .null,
        ])
      }
    } else {
      capabilitiesPayload = [:]
    }

    responder.respond(
      status: .success,
      data: [
        "environment": .string("ios"),
        "hostVersion": .string(hostVersion),
        "capabilities": .object(capabilitiesPayload),
      ],
      error: nil
    )
  }
}
