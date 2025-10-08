import UIKit
import WebKit

final class WebviewVC: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {

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
        setupEdgeSwipeBack()
        loadURL(startURL)
    }

    // MARK: - Setup
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEdgeSwipeBack() {
        // Более корректный "свайп слева — назад"
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left
        edgePan.delegate = self
        view.addGestureRecognizer(edgePan)
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized, webView.canGoBack {
            webView.goBack()
        }
    }

    // MARK: - Loading
    private func loadURL(_ url: URL) {
        print("➡️ Загружаем: \(url.absoluteString)")
        let request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 30)
        webView.load(request)
    }

    // MARK: - Safe URL helper (улучшённый)
    private func safeURL(from raw: String) -> URL? {
        var rawString = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        rawString = rawString.replacingOccurrences(of: "\n", with: "")

        if !rawString.lowercased().hasPrefix("http://") &&
            !rawString.lowercased().hasPrefix("https://") {
            rawString = "https://" + rawString
        }

        // Попробуем как есть
        if let direct = URL(string: rawString) {
            return direct
        }

        // Если не получилось — попробуем декодировать (убираем двойное кодирование)
        let decoded = rawString.removingPercentEncoding ?? rawString

        // Затем корректно закодируем фрагменты/параметры (разрешаем фрагменты)
        if let encoded = decoded.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let fixed = URL(string: encoded) {
            return fixed
        }

        print("⚠️ safeURL: не удалось обработать ссылку: \(raw)")
        return nil
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let rawString = url.absoluteString
        print("🔗 Навигация: \(rawString)")

        // Если это http/https — обычно разрешаем, но для сложных якорей принудительно загружаем
        if let safe = safeURL(from: rawString) {
            // Если в ссылке есть #:~:text= или закодированный # — WKWebView может некорректно обработать — загружаем вручную
            if safe.absoluteString.contains("#:~:text=") || safe.absoluteString.contains("%23") {
                print("⚙️ Принудительная загрузка сложной якорной ссылки")
                decisionHandler(.cancel)
                loadURL(safe)
                return
            }
        }

        // Обработка внешних схем (itms-apps, intent, appsflyer и т.д.)
        if let scheme = url.scheme?.lowercased(), scheme != "http", scheme != "https" {
            if UIApplication.shared.canOpenURL(url) {
                // NOTE: для некоторых кастомных схем canOpenURL требует LSApplicationQueriesSchemes в Info.plist
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("🚫 Не удалось открыть внешнюю схему (canOpenURL == false): \(url.absoluteString)")
            }
            decisionHandler(.cancel)
            return
        }

        // Нормальная навигация
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
                print("⚠️ Превышено количество попыток при ERR_TOO_MANY_REDIRECTS — очищаем cookies и кеш")
                clearCookiesAndRetry()
                return
            }

            redirectRetryCount += 1
            print("🔄 Повторная загрузка (\(redirectRetryCount)) после ERR_TOO_MANY_REDIRECTS")

            let urlToReload = SaveService.lastUrl ?? currentURL ?? startURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.loadURL(urlToReload)
            }
        }
    }

    // MARK: - Очистка cookies и кеша
    private func clearCookiesAndRetry() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()

        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {
                print("🧹 Cookies и кеш очищены, пробуем заново.")
                self.redirectRetryCount = 0
                let urlToReload = SaveService.lastUrl ?? self.startURL
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.loadURL(urlToReload)
                }
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
