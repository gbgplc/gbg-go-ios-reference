import WebKit

/// Weak proxy that breaks the WKUserContentController → BridgeHost retain cycle.
/// WKUserContentController strongly retains its script message handlers. By inserting
/// a proxy that holds a weak reference to the real handler, the host can be deallocated
/// normally when the view is torn down.
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
  weak var delegate: WKScriptMessageHandler?

  init(delegate: WKScriptMessageHandler) {
    self.delegate = delegate
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    delegate?.userContentController(userContentController, didReceive: message)
  }
}

/// Configures a `WKWebView` for use with the GBGBridge message channel.
///
/// This type provides static helpers to inject the bootstrap script, register the
/// script message handler, and attach a ``BridgeHost`` to a web view.
public struct BridgeWebViewConfigurator {
  private static let defaultBootstrapSource =
    "window.GBGBridge = window.GBGBridge || {}; window.GBGBridge.receive = window.GBGBridge.receive || function(){};"

  private init() {}

  /// Configures an existing `WKWebView` with the bridge bootstrap script and message handler.
  ///
  /// The bootstrap script and handler are injected into the main frame only;
  /// sub-frames (iframes) cannot access the native bridge.
  ///
  /// - Parameters:
  ///   - webView: The web view to configure.
  ///   - host: The bridge host to attach.
  @MainActor public static func configure(
    _ webView: WKWebView,
    host: BridgeHost
  ) {
    // forMainFrameOnly: true — the bridge script and message handler are
    // only injected into the top-level frame. Sub-frames (iframes) cannot
    // access the native bridge. This prevents untrusted third-party iframes
    // from invoking native capabilities.
    //
    // If iframe bridging is needed in the future, add an explicit opt-in
    // parameter rather than defaulting to all-frames.
    let script = WKUserScript(
      source: host.configuration.bootstrapScript ?? defaultBootstrapSource,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: true
    )

    let controller = webView.configuration.userContentController
    controller.addUserScript(script)
    controller.add(ScriptMessageProxy(delegate: host), name: "gbgBridge")

    host.attach(webView: webView)
  }

  /// Creates a new `WKWebView` pre-configured with the bridge message channel.
  ///
  /// - Parameter host: The bridge host to attach.
  /// - Returns: A configured `WKWebView` ready for loading content.
  @MainActor public static func makeWebView(
    host: BridgeHost
  ) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: configuration)
    configure(webView, host: host)
    return webView
  }
}
