import SwiftUI
import WebKit

struct MarkdownPreview: NSViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        webView.navigationDelegate = context.coordinator
        // Load content immediately
        context.coordinator.lastContent = markdown
        let rendered = MarkdownParser.toHTML(markdown)
        let html = buildHTML(rendered)
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard markdown != context.coordinator.lastContent else { return }
        context.coordinator.lastContent = markdown
        let rendered = MarkdownParser.toHTML(markdown)
        let html = buildHTML(rendered)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
            :root {
                color-scheme: light dark;
                --text: #1d1d1f;
                --bg: #ffffff;
                --secondary: #6e6e73;
                --border: #d2d2d7;
                --code-bg: #f5f5f7;
                --accent: #0071e3;
            }

            @media (prefers-color-scheme: dark) {
                :root {
                    --text: #f5f5f7;
                    --bg: #1e1e1e;
                    --secondary: #a1a1a6;
                    --border: #424245;
                    --code-bg: #2a2a2a;
                    --accent: #2997ff;
                }
            }

            * { margin: 0; padding: 0; box-sizing: border-box; }

            body {
                font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
                font-size: 15px;
                line-height: 1.7;
                padding: 32px 40px;
                max-width: 800px;
                -webkit-font-smoothing: antialiased;
                color: var(--text);
                background: var(--bg);
            }

            h1, h2, h3, h4, h5, h6 {
                font-weight: 600;
                margin-top: 1.6em;
                margin-bottom: 0.6em;
                line-height: 1.3;
            }
            h1 { font-size: 2em; font-weight: 700; margin-top: 0; }
            h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
            h3 { font-size: 1.25em; }
            p { margin-bottom: 1em; }
            a { color: var(--accent); text-decoration: none; }
            strong { font-weight: 600; }

            code {
                font-family: "SF Mono", Menlo, monospace;
                font-size: 0.88em;
                background: var(--code-bg);
                padding: 0.15em 0.4em;
                border-radius: 4px;
            }

            pre {
                margin: 1.2em 0;
                padding: 16px 20px;
                background: var(--code-bg);
                border-radius: 8px;
                overflow-x: auto;
            }
            pre code { background: none; padding: 0; font-size: 0.85em; }

            blockquote {
                margin: 1.2em 0;
                padding: 12px 20px;
                border-left: 3px solid var(--accent);
                background: var(--code-bg);
                border-radius: 0 6px 6px 0;
                color: var(--secondary);
            }
            blockquote p { margin-bottom: 0; }

            ul, ol { margin: 0.8em 0; padding-left: 1.8em; }
            li { margin-bottom: 0.3em; }

            hr { border: none; height: 1px; background: var(--border); margin: 2em 0; }
            img { max-width: 100%; border-radius: 8px; margin: 1em 0; }

            table { border-collapse: collapse; margin: 1.2em 0; width: 100%; }
            th, td { border: 1px solid var(--border); padding: 8px 12px; text-align: left; }
            th { font-weight: 600; background: var(--code-bg); }
            h6 { color: var(--secondary); }
            del { color: var(--secondary); }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastContent: String?
    }
}
