import SwiftUI
import WebKit

struct MainView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            Color(hex: "#06080e").ignoresSafeArea()

            VStack(spacing: 0) {
                // Trial banner
                if !appState.isLicensed && appState.trialDaysLeft <= 14 {
                    HStack {
                        Text("trial: \(appState.trialDaysLeft) days left")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(appState.trialDaysLeft <= 3 ? Color(hex: "#ffaa66") : Color(hex: "#88aacc"))
                        Spacer()
                        Button("buy 4MA") {
                            if let url = URL(string: "https://senderpa.github.io/4ma/support") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00ffcc"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#1a1a2e"))
                }

                // Main content -- WebView pointing to 4MA backend
                FourMAWebView(serverURL: appState.serverURL.isEmpty
                    ? "http://localhost:5090"
                    : appState.serverURL)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - WKWebView wrapper with full media/JS/LAN support

struct FourMAWebView: UIViewRepresentable {
    let serverURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        // -- Web content configuration --
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences

        // Media: inline playback, no user gesture required
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Allow audio to play even when the ringer switch is silent
        config.allowsAirPlayForMediaPlayback = true

        // Data store (cookies, localStorage persistence)
        config.websiteDataStore = .default()

        // User content controller for JS bridge (ready for future use)
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        // -- Create the web view --
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Transparent background so the dark ZStack shows through during load
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        // Bounce at edges for natural iOS feel
        webView.scrollView.bounces = true

        // Allow back/forward swipe gestures
        webView.allowsBackForwardNavigationGestures = true

        // Custom user agent so 4MA backend can detect the native app
        if let defaultUA = webView.value(forKey: "userAgent") as? String {
            webView.customUserAgent = "\(defaultUA) 4MA-iOS/1.0"
        } else {
            webView.customUserAgent = "Mozilla/5.0 4MA-iOS/1.0"
        }

        // Allow inspection in Safari dev tools (debug builds)
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        // Load the server URL
        if let url = URL(string: serverURL) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reload if serverURL changed
        if let current = uiView.url?.absoluteString,
           current != serverURL,
           let url = URL(string: serverURL) {
            uiView.load(URLRequest(url: url))
        }
    }

    // MARK: - Coordinator (Navigation + UI Delegate)

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        // Allow navigation to local network and the 4MA backend
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Open external links (non-4MA) in Safari
            if let url = navigationAction.request.url,
               let host = url.host,
               !host.contains("localhost"),
               !host.contains("127.0.0.1"),
               !isLANAddress(host),
               navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // Handle SSL certificate errors for local/self-signed certs
        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            // Trust local network servers (self-signed certs on LAN)
            if let host = challenge.protectionSpace.host,
               (host.contains("localhost") || host.contains("127.0.0.1") || isLANAddress(host)),
               let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
                return
            }
            completionHandler(.performDefaultHandling, nil)
        }

        // Handle JavaScript alerts
        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            completionHandler()
        }

        // Handle JavaScript confirm dialogs
        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }

        // Handle window.open() -- open new windows in the same web view
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? false) {
                webView.load(navigationAction.request)
            }
            return nil
        }

        // Retry on provisional navigation failure (e.g., server not yet up)
        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            // Retry after 3 seconds if server is unreachable
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let url = webView.url {
                    webView.load(URLRequest(url: url))
                }
            }
        }

        // MARK: - Helpers

        private func isLANAddress(_ host: String) -> Bool {
            host.hasPrefix("192.168.") ||
            host.hasPrefix("10.") ||
            host.hasPrefix("172.16.") ||
            host.hasPrefix("172.17.") ||
            host.hasPrefix("172.18.") ||
            host.hasPrefix("172.19.") ||
            host.hasPrefix("172.2") ||
            host.hasPrefix("172.3") ||
            host.hasSuffix(".local")
        }
    }
}
