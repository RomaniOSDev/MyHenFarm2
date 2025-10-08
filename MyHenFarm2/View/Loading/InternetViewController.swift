import UIKit
import WebKit

final class WebviewVC: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private let startURL: URL
    
    private var redirectRetryCount = 0
    private let maxRetryCount = 5

    // MARK: - Init
    init(url: URL) {
        self.startURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не используется")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL(startURL)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - URL Loading
    private func loadURL(_ url: URL) {
        print("➡️ Загружаем: \(url.absoluteString)")
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30
        )
        webView.load(request)
    }

    // MARK: - Safe URL helper
    private func safeURL(from raw: String) -> URL? {
        var rawString = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if !rawString.lowercased().hasPrefix("http://") &&
            !rawString.lowercased().hasPrefix("https://") {
            rawString = "https://" + rawString
        }

        if let url = URL(string: rawString) {
            return url
        }

        if let encoded = rawString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let encodedURL = URL(string: encoded) {
            return encodedURL
        }

        print("⚠️ safeURL: не удалось создать корректный URL из строки: \(raw)")
        return nil
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if navigationAction.navigationType == .linkActivated,
           let clickedURL = navigationAction.request.url {
            print("🔗 Клик по ссылке: \(clickedURL.absoluteString)")

            if let safe = safeURL(from: clickedURL.absoluteString) {
                decisionHandler(.cancel)
                loadURL(safe)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        SaveService.lastUrl = url
        redirectRetryCount = 0
        print("✅ Успешно загружено: \(url.absoluteString)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error, currentURL: webView.url)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error, currentURL: webView.url)
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error, currentURL: URL?) {
        let nsError = error as NSError
        print("❌ Ошибка загрузки: \(nsError.code) — \(nsError.localizedDescription)")

        if nsError.code == NSURLErrorHTTPTooManyRedirects {
            guard redirectRetryCount < maxRetryCount else {
                print("⚠️ Превышено количество повторных попыток после редиректов")
                return
            }

            redirectRetryCount += 1
            print("🔄 Повторная загрузка после ERR_TOO_MANY_REDIRECTS (\(redirectRetryCount))")

            // Загружаем последнюю успешную ссылку, если есть
            let urlToReload = SaveService.lastUrl ?? currentURL ?? startURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.loadURL(urlToReload)
            }
        }
    }
}

// MARK: - SaveService
struct SaveService {
    static var lastUrl: URL? {
        get { UserDefaults.standard.url(forKey: "LastUrl") }
        set { UserDefaults.standard.set(newValue, forKey: "LastUrl") }
    }
    static var time: String? {
        get { UserDefaults.standard.string(forKey: "Time") }
        set { UserDefaults.standard.set(newValue, forKey: "Time") }
    }
}
