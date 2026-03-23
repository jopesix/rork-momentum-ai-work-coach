import SwiftUI
import WebKit

struct MoWidgetView: UIViewRepresentable {
    let agentId: String
    let context: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // Use persistent data store so ElevenLabs consent is remembered across sessions
        config.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        // Auto-grant microphone permission so the call starts without a browser prompt
        webView.uiDelegate = context.coordinator
        loadHTML(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadHTML(in webView: WKWebView) {
        guard !agentId.isEmpty else { return }

        let escapedContext = self.context
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            background: transparent;
            font-family: -apple-system, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
          }
          elevenlabs-convai {
            --el-primary-color: #1A7A6E;
            --el-background-color: transparent;
          }
        </style>
        </head>
        <body>
          <elevenlabs-convai
            agent-id="\(agentId)"
            dynamic-variables='{"context":"\(escapedContext)"}'>
          </elevenlabs-convai>
          <script src="https://elevenlabs.io/convai-widget/index.js" async></script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://elevenlabs.io"))
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKUIDelegate {
        /// Auto-grant microphone (and camera) permission to the ElevenLabs widget.
        /// The app already holds NSMicrophoneUsageDescription permission from iOS —
        /// this just passes that grant through to the embedded WebView so the call
        /// can start without a secondary browser-level prompt.
        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            decisionHandler(.grant)
        }

        /// Suppress the JavaScript alert/confirm dialogs the widget may show
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }
    }
}
