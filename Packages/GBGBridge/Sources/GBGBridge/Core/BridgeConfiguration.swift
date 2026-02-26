import Foundation

/// Describes a single capability exposed by the native host.
public struct BridgeCapabilityInfo: Codable, Sendable {
  /// Whether the capability is currently supported and available.
  public var supported: Bool
  /// Optional semver version string for the capability implementation.
  public var version: String?
  /// Optional constraints or metadata for the capability (e.g. max resolution).
  public var constraints: [String: JSONValue]?
  /// The current permission state as a string (e.g. `"granted"`, `"denied"`).
  public var permissionState: String?

  /// Creates a capability info descriptor.
  ///
  /// - Parameters:
  ///   - supported: Whether the capability is supported.
  ///   - version: Optional version string.
  ///   - constraints: Optional constraints dictionary.
  ///   - permissionState: Optional permission state string.
  public init(
    supported: Bool,
    version: String? = nil,
    constraints: [String: JSONValue]? = nil,
    permissionState: String? = nil
  ) {
    self.supported = supported
    self.version = version
    self.constraints = constraints
    self.permissionState = permissionState
  }
}

/// Configuration for a ``BridgeHost`` instance.
public struct BridgeConfiguration: Sendable {
  /// A semver-style version string identifying the host application.
  public var hostVersion: String
  /// The set of capabilities the host declares, keyed by capability identifier.
  public var capabilities: [String: BridgeCapabilityInfo]
  /// Optional JavaScript to inject at document start instead of the default bootstrap stub.
  public var bootstrapScript: String?

  /// Creates a bridge configuration.
  ///
  /// - Parameters:
  ///   - hostVersion: The host application version string.
  ///   - capabilities: A dictionary of capability descriptors.
  ///   - bootstrapScript: Optional custom bootstrap JavaScript.
  public init(
    hostVersion: String,
    capabilities: [String: BridgeCapabilityInfo],
    bootstrapScript: String? = nil
  ) {
    self.hostVersion = hostVersion
    self.capabilities = capabilities
    self.bootstrapScript = bootstrapScript
  }
}
