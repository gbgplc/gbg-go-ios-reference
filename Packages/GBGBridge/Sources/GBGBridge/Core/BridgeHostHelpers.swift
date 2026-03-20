import Foundation

struct CustomCapabilityEntry {
  let id: String
  let version: String?
  let handler: @Sendable (BridgeMessage, BridgeResponder) async -> Void
}

// SAFETY: @unchecked Sendable — `host` is weak, `correlationId` and `action` are
// immutable, and `hasResponded` is only mutated from the @MainActor Task inside
// respond(). If this type is ever accessed from multiple concurrent tasks, switch
// to an actor or use a lock.
final class CapabilityResponder: BridgeResponder, @unchecked Sendable {
  private weak var host: BridgeHost?
  private let correlationId: String
  private let action: String
  private var hasResponded = false

  init(host: BridgeHost, correlationId: String, action: String) {
    self.host = host
    self.correlationId = correlationId
    self.action = action
  }

  func respond(status: BridgeResponseStatus, data: [String: JSONValue]?, error: BridgeErrorPayload?) {
    Task { @MainActor [weak host] in
      guard !self.hasResponded else { return }
      self.hasResponded = true

      guard let host else {
        return
      }
      host.respond(
        to: correlationId,
        action: action,
        status: status,
        data: data,
        error: error
      )
    }
  }
}

// Internal handler wrapper that routes requests to a typed CaptureCapability slot.
// SAFETY: @unchecked Sendable — all stored properties are immutable (`let`).
// The `handle` method dispatches to MainActor.run before accessing the slot.
// If mutable state is added in the future, this annotation must be reconsidered.
final class TypedSlotHandler: BridgeCapabilityHandler, @unchecked Sendable {
  let action: String
  private let slot: CaptureCapability

  init(slot: CaptureCapability) {
    self.action = slot.actionId
    self.slot = slot
  }

  func handle(request: BridgeMessage, responder: BridgeResponder) async {
    await MainActor.run {
      slot.handleRequest(request, responder: responder)
    }
  }
}

// Internal handler wrapper for custom capabilities registered via registerCustomCapability.
// SAFETY: @unchecked Sendable — all stored properties are immutable (`let`).
// The handler closure is already marked @Sendable by the caller.
// If mutable state is added in the future, this annotation must be reconsidered.
final class CustomCapabilityHandler: BridgeCapabilityHandler, @unchecked Sendable {
  let action: String
  private let handler: @Sendable (BridgeMessage, BridgeResponder) async -> Void

  init(action: String, handler: @escaping @Sendable (BridgeMessage, BridgeResponder) async -> Void) {
    self.action = action
    self.handler = handler
  }

  func handle(request: BridgeMessage, responder: BridgeResponder) async {
    await handler(request, responder)
  }
}
