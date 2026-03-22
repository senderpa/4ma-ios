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

                // Main content — WebView pointing to 4MA backend
                FourMAWebView(serverURL: appState.serverURL.isEmpty
                    ? "http://localhost:5090"
                    : appState.serverURL)
            }
        }
    }
}

struct FourMAWebView: UIViewRepresentable {
    let serverURL: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        if let url = URL(string: serverURL) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
