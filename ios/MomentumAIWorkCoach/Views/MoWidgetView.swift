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
        // Persistent data store so any saved state carries across sessions
        config.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
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

    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {

        // MARK: - WKUIDelegate

        /// Auto-grant microphone permission so the ElevenLabs call connects immediately.
        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            decisionHandler(.grant)
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            // Auto-confirm any JS dialogs (e.g. consent confirmations)
            completionHandler(true)
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Poll the ElevenLabs widget's shadow DOM and auto-click any consent/accept button
            // so the user never has to interact with the privacy popup.
            autoAcceptConsent(in: webView, attempts: 0)
        }

        private func autoAcceptConsent(in webView: WKWebView, attempts: Int) {
            guard attempts < 20 else { return } // give up after ~10 seconds

            let js = """
            (function() {
                var widget = document.querySelector('elevenlabs-convai');
                if (!widget) return 'no-widget';
                var root = widget.shadowRoot;
                if (!root) return 'no-shadow';
                var buttons = Array.from(root.querySelectorAll('button, [role="button"]'));
                var acceptBtn = buttons.find(function(b) {
                    var t = (b.textContent || b.innerText || '').trim().toLowerCase();
                    return t.includes('accept') || t.includes('agree') || t.includes('continue') || t.includes('got it') || t.includes('ok');
                });
                if (acceptBtn) { acceptBtn.click(); return 'clicked'; }
                return 'not-found';
            })();
            """

            webView.evaluateJavaScript(js) { [weak self] result, _ in
                let status = result as? String ?? "error"
                if status != "clicked" {
                    // Not found yet — try again in 500ms
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.autoAcceptConsent(in: webView, attempts: attempts + 1)
                    }
                }
            }
        }
    }
}
