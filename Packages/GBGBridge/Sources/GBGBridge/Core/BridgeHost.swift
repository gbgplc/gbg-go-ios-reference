import Combine
import Foundation
import WebKit

/// Central coordinator for the GBGBridge native-to-web communication layer.
///
/// `BridgeHost` manages a bidirectional message channel between a `WKWebView` and
/// native Swift code. It routes incoming requests to registered capability handlers,
/// publishes received messages for observation, and provides methods to send events
/// and responses back to the web layer.
///
/// This class is `@MainActor`-isolated and conforms to `ObservableObject` so it can
/// drive SwiftUI views directly.
@MainActor
public class BridgeHost: NSObject, ObservableObject, WKScriptMessageHandler {
  /// All messages received from the web layer, capped at the most recent 200 entries.
  @Published public var receivedMessages: [BridgeMessage] = []
  /// Incoming requests that have no registered handler and are awaiting manual resolution.
  @Published public var pendingRequests: [BridgeMessage] = []
  /// Current capability map keyed by capability identifier, indicating support status.
  @Published public var capabilities: [String: Bool]
  /// The most recent error message, or `nil` if no error is active.
  @Published public var lastError: String?

  /// Optional delegate that receives callbacks for all incoming messages and unhandled requests.
  public weak var delegate: BridgeHostDelegate?
  /// The configuration used to initialise this host.
  public private(set) var configuration: BridgeConfiguration
  private let hostVersion: String
  private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    return encoder
  }()
  private let jsonDecoder = JSONDecoder()
  /// The bridge protocol version included in all outbound messages.
  public static let protocolVersion = "1.0"
  private static let maxReceivedMessages = 200
  private var handlers: [String: any BridgeCapabilityHandler] = [:]
  private weak var webView: WKWebView?
  private var slotCancellables = Set<AnyCancellable>()

  /// Typed capability slot for document capture requests (`camera.document`).
  public let documentCapture: CaptureCapability
  /// Typed capability slot for selfie capture requests (`camera.selfie`).
  public let selfieCapture: CaptureCapability

  // Custom capability storage
  private var customCapabilities: [String: CustomCapabilityEntry] = [:]
  private var usesTypedSlots: Bool = false

  /// Creates a bridge host with a full configuration.
  ///
  /// Use this initialiser when you want to provide a pre-built capability map
  /// (e.g. from a server-driven config). For the simpler typed-slot API, use
  /// ``init(hostVersion:)`` instead.
  ///
  /// - Parameter configuration: The bridge configuration describing host version and capabilities.
  public init(configuration: BridgeConfiguration) {
    self.configuration = configuration
    self.hostVersion = configuration.hostVersion
    self.capabilities = configuration.capabilities.mapValues(\.supported)
    self.documentCapture = CaptureCapability(id: "camera.document", actionId: "camera.document.capture")
    self.selfieCapture = CaptureCapability(id: "camera.selfie", actionId: "camera.selfie.capture")
    super.init()

    // Forward objectWillChange from typed slots so SwiftUI picks up
    // nested ObservableObject changes (e.g. activeRequest).
    forwardSlotChanges()

    let queryHandler = CapabilityQueryHandler(
      capabilities: { [weak self] in self?.capabilities ?? [:] },
      hostVersion: configuration.hostVersion
    )
    register(handler: queryHandler)
  }

  /// Creates a bridge host using the typed-slot API.
  ///
  /// Capabilities are derived automatically from the ``documentCapture`` and
  /// ``selfieCapture`` slots, plus any custom capabilities registered later
  /// via ``registerCustomCapability(_:version:handler:)``.
  ///
  /// - Parameter hostVersion: A semver-style version string identifying the host application.
  public convenience init(hostVersion: String) {
    let config = BridgeConfiguration(hostVersion: hostVersion, capabilities: [:])
    self.init(configuration: config)
    usesTypedSlots = true

    // Re-register the query handler with the rich provider
    let richQueryHandler = CapabilityQueryHandler(
      richCapabilities: { [weak self] in self?.buildRichCapabilities() ?? [:] },
      hostVersion: hostVersion
    )
    register(handler: richQueryHandler)

    // Register internal handlers for typed slots
    // These use register(handler:) so they participate in the normal handler dictionary
    register(handler: TypedSlotHandler(slot: documentCapture))
    register(handler: TypedSlotHandler(slot: selfieCapture))
  }

  /// Registers a capability handler for its declared action.
  ///
  /// If a handler is already registered for the same action, it is replaced.
  ///
  /// - Parameter handler: The handler to register.
  public func register(handler: any BridgeCapabilityHandler) {
    handlers[handler.action] = handler
  }

  /// Removes the capability handler registered for the given action.
  ///
  /// - Parameter action: The action identifier to unregister.
  public func unregister(action: String) {
    handlers.removeValue(forKey: action)
  }

  /// Registers a lightweight custom capability with a closure-based handler.
  ///
  /// Custom capabilities appear in `capability.query` responses and are routed
  /// through the provided handler when a matching request arrives.
  ///
  /// - Parameters:
  ///   - id: A unique capability identifier (also used as the action key).
  ///   - version: Optional semver version string; defaults to `"1.0"` in query responses.
  ///   - handler: An async closure invoked when a request for this capability arrives.
  public func registerCustomCapability(
    _ id: String,
    version: String? = nil,
    handler: @escaping @Sendable (BridgeMessage, BridgeResponder) async -> Void
  ) {
    let entry = CustomCapabilityEntry(id: id, version: version, handler: handler)
    customCapabilities[id] = entry

    // Register a handler that wraps the custom handler.
    // If a typed slot later registers for the same action, it will overwrite this.
    let actionId = id  // custom capabilities use id as the action
    let wrappedHandler = CustomCapabilityHandler(action: actionId, handler: handler)
    // Only register if no typed slot already handles this action
    if handlers[actionId] == nil {
      register(handler: wrappedHandler)
    }
  }

  /// Attaches the host to a `WKWebView`, enabling message dispatch.
  ///
  /// - Parameter webView: The web view to attach to. Only one web view may be attached at a time.
  public func attach(webView: WKWebView) {
    self.webView = webView
  }

  /// Detaches the host from its WebView, removing the script message handler
  /// and breaking any remaining references. Call this when the WebView is being
  /// removed from the view hierarchy (e.g. in onDisappear or when navigating away).
  public func detach() {
    // Cancel any in-progress capture requests to prevent leaked CheckedContinuations.
    // cancelIfBusy() safely resumes the continuation with .cancelled and clears
    // activeRequest. It is a no-op if no request is in flight.
    documentCapture.cancelIfBusy(reason: "BridgeHost detached")
    selfieCapture.cancelIfBusy(reason: "BridgeHost detached")

    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "gbgBridge")
    webView?.configuration.userContentController.removeAllUserScripts()
    webView = nil
  }

  /// Clears the ``lastError`` value, setting it to `nil`.
  public func clearError() {
    lastError = nil
  }

  /// Sends a one-way event to the web layer.
  ///
  /// Events are fire-and-forget messages that do not expect a response.
  ///
  /// - Parameters:
  ///   - action: The event action identifier.
  ///   - data: A dictionary of JSON-compatible values to include in the payload.
  public func send(event action: String, data: [String: JSONValue]) {
    let payload = BridgePayload(action: action, data: data, status: nil, error: nil)
    send(type: .event, correlationId: "ios-event-\(UUID().uuidString)", payload: payload)
  }

  /// Sends a response to a pending request, matched by correlation ID.
  ///
  /// The matching request is automatically removed from ``pendingRequests``.
  /// If no matching request is found, the call is silently ignored.
  ///
  /// - Parameters:
  ///   - correlationId: The correlation ID of the original request.
  ///   - status: The response status.
  ///   - data: Optional response data.
  ///   - error: Optional error payload.
  public func respond(
    to correlationId: String,
    status: BridgeResponseStatus,
    data: [String: JSONValue]? = nil,
    error: BridgeErrorPayload? = nil
  ) {
    guard let request = pendingRequests.first(where: { $0.correlationId == correlationId }) else {
      return
    }

    let payload = BridgePayload(
      action: request.payload.action,
      data: data,
      status: status,
      error: error
    )

    send(type: .response, correlationId: correlationId, payload: payload)
    pendingRequests.removeAll { $0.correlationId == correlationId }
  }

  /// Sends a response with an explicit action, without requiring a matching pending request.
  ///
  /// Use this overload when responding from a capability handler that has already
  /// consumed the request from the pending queue.
  ///
  /// - Parameters:
  ///   - correlationId: The correlation ID of the original request.
  ///   - action: The action identifier for the response payload.
  ///   - status: The response status.
  ///   - data: Optional response data.
  ///   - error: Optional error payload.
  public func respond(
    to correlationId: String,
    action: String,
    status: BridgeResponseStatus,
    data: [String: JSONValue]? = nil,
    error: BridgeErrorPayload? = nil
  ) {
    let payload = BridgePayload(
      action: action,
      data: data,
      status: status,
      error: error
    )

    send(type: .response, correlationId: correlationId, payload: payload)
  }

  public func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard message.name == "gbgBridge" else {
      return
    }

    processIncomingBody(message.body)
  }

  func processIncomingBody(_ body: Any) {
    do {
      let bridgeMessage = try decodeEnvelope(body)
      receivedMessages.append(bridgeMessage)
      // Trim to cap — use suffix to avoid O(n) removeFirst on Array.
      if receivedMessages.count > Self.maxReceivedMessages {
        receivedMessages = Array(receivedMessages.suffix(Self.maxReceivedMessages))
      }
      delegate?.bridgeHost(self, didReceive: bridgeMessage)
      handleIncomingRequest(bridgeMessage)
    } catch {
      lastError = "Failed to decode message: \(error.localizedDescription)"
    }
  }

  private func handleIncomingRequest(_ bridgeMessage: BridgeMessage) {
    guard bridgeMessage.type == .request else {
      return
    }

    if let handler = handlers[bridgeMessage.payload.action] {
      let responder = CapabilityResponder(
        host: self,
        correlationId: bridgeMessage.correlationId,
        action: bridgeMessage.payload.action
      )

      Task {
        await handler.handle(request: bridgeMessage, responder: responder)
      }
      return
    }

    pendingRequests.append(bridgeMessage)
    if pendingRequests.count > 50 {
      lastError = "Warning: \(pendingRequests.count) pending requests — possible request leak"
    }
    delegate?.bridgeHost(self, unhandledRequest: bridgeMessage)
  }

  // MARK: - Slot change forwarding

  private func forwardSlotChanges() {
    for slot in [documentCapture, selfieCapture] {
      slot.objectWillChange.sink { [weak self] _ in
        self?.objectWillChange.send()
      }.store(in: &slotCancellables)
    }
  }

  // MARK: - Rich capabilities (typed slots + custom)

  private func buildRichCapabilities() -> [String: BridgeCapabilityInfo] {
    var result: [String: BridgeCapabilityInfo] = [:]

    // Add custom capabilities first
    for (id, entry) in customCapabilities {
      result[id] = BridgeCapabilityInfo(
        supported: true,
        version: entry.version ?? "1.0"
      )
    }

    // Typed slots override custom capabilities with the same id
    let typedSlots: [CaptureCapability] = [documentCapture, selfieCapture]
    for slot in typedSlots where slot.handler != nil {
      result[slot.id] = slot.buildCapabilityInfo()
    }

    return result
  }

  // MARK: - Send

  private func send(type: BridgeMessageType, correlationId: String, payload: BridgePayload) {
    guard let webView else {
      lastError = "WebView not attached"
      return
    }

    let envelope = BridgeMessage(
      version: Self.protocolVersion,
      correlationId: correlationId,
      type: type,
      timestamp: Date().timeIntervalSince1970 * 1000,
      payload: payload
    )

    do {
      let data = try jsonEncoder.encode(envelope)
      guard let jsonString = String(data: data, encoding: .utf8) else {
        lastError = "Failed to encode message"
        return
      }

      // callAsyncJavaScript passes arguments safely without string interpolation.
      // The `json` argument is available as a local variable inside the JS body.
      let script = """
      if (window.GBGBridge && window.GBGBridge.receive) {
          window.GBGBridge.receive(JSON.parse(json));
      }
      """

      webView.callAsyncJavaScript(
        script,
        arguments: ["json": jsonString],
        in: nil,
        in: .page
      ) { [weak self] result in
        if case .failure(let error) = result {
          Task { @MainActor in
            self?.lastError = "callAsyncJavaScript failed: \(error.localizedDescription)"
          }
        }
      }
    } catch {
      lastError = "Failed to encode envelope: \(error.localizedDescription)"
    }
  }

  private func decodeEnvelope(_ body: Any) throws -> BridgeMessage {
    if let dictionary = body as? [String: Any] {
      let data = try JSONSerialization.data(withJSONObject: dictionary)
      return try jsonDecoder.decode(BridgeMessage.self, from: data)
    }

    if let jsonString = body as? String {
      guard let data = jsonString.data(using: .utf8) else {
        throw NSError(domain: "BridgeHost", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 JSON string"])
      }
      return try jsonDecoder.decode(BridgeMessage.self, from: data)
    }

    throw NSError(domain: "BridgeHost", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported message body type"])
  }
}
