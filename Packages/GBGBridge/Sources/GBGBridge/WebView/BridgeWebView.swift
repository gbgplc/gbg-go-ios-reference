import SwiftUI
import WebKit

/// A SwiftUI view that wraps a `WKWebView` pre-configured with the GBGBridge message channel.
///
/// Use this view to embed a bridge-enabled web view in a SwiftUI layout. The view automatically
/// configures the web view, attaches the bridge host, and manages the navigation delegate.
public struct BridgeWebView: UIViewRepresentable {
  /// The URL to load in the web view.
  public let url: URL
  /// The bridge host managing native-to-web communication.
  @ObservedObject public var host: BridgeHost

  /// Creates a bridge web view.
  ///
  /// - Parameters:
  ///   - url: The URL to load.
  ///   - host: The bridge host to attach to the web view.
  public init(url: URL, host: BridgeHost) {
    self.url = url
    self.host = host
  }

  public func makeUIView(context: Context) -> WKWebView {
    let webView = BridgeWebViewConfigurator.makeWebView(host: host)
    #if DEBUG
    if #available(iOS 16.4, *) {
      webView.isInspectable = true
    }
    #endif
    webView.navigationDelegate = context.coordinator
    context.coordinator.lastRequestedURL = url
    webView.load(URLRequest(url: url))
    return webView
  }

  public func updateUIView(_ webView: WKWebView, context: Context) {
    guard context.coordinator.lastRequestedURL != url else { return }
    context.coordinator.lastRequestedURL = url
    webView.load(URLRequest(url: url))
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(host: host)
  }

  public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
    coordinator.host.detach()
  }

  public final class Coordinator: NSObject, WKNavigationDelegate {
    let host: BridgeHost
    var lastRequestedURL: URL?

    init(host: BridgeHost) {
      self.host = host
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      host.lastError = "Navigation failed: \(error.localizedDescription)"
    }

    public func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      host.lastError = "Page load failed: \(error.localizedDescription)"
    }
  }
}
