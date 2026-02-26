import Foundation

/// Represents the current state of a system permission (e.g. camera access).
public enum PermissionState: String, Codable, Sendable {
  /// The user has granted permission.
  case granted
  /// The user has explicitly denied permission.
  case denied
  /// The user has not yet been prompted for permission.
  case notDetermined
  /// Permission is restricted by device policy (e.g. parental controls).
  case restricted
  /// The permission is not applicable to this capability.
  case notApplicable
}
