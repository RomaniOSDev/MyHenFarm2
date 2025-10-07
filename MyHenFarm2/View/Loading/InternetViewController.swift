import UIKit
import WebKit

final class WebviewVC: UIViewController, WKNavigationDelegate {
    
    private var webView: WKWebView!
    private let startURL: URL
    private var redirectRetryCount = 0
    private let maxRetryCount = 3
    
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
    
    // MARK: - Setup
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
    
    // MARK: - Loading
    private func loadURL(_ url: URL) {
        print("➡️ Загружаем: \(url.absoluteString)")
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30
        )
        webView.load(request)
    }
    
    // MARK: - Safe URL
    private func safeURL(from raw: String) -> URL? {
        var rawString = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !rawString.lowercased().hasPrefix("http://") &&
           !rawString.lowercased().hasPrefix("https://") {
            rawString = "https://" + rawString
        }
        
        if let direct = URL(string: rawString) {
            return direct
        }
        if let encoded = rawString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let encodedURL = URL(string: encoded) {
            return encodedURL
        }
        
        print("⚠️ safeURL: не удалось создать корректный URL из строки: \(raw)")
        return nil
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let scheme = url.scheme?.lowercased() ?? ""
        print("🌐 Навигация к URL: \(url.absoluteString)")
        
        // Разрешаем обычные http/https
        if ["http", "https"].contains(scheme) {
            decisionHandler(.allow)
            return
        }
        
        // Открываем внешние схемы (App Store, Appsflyer, Telegram, и т.д.)
        if UIApplication.shared.canOpenURL(url) {
            print("📲 Открываем внешнюю ссылку: \(url.absoluteString)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        // Остальные схемы блокируем
        print("🚫 Блокируем неизвестную схему: \(scheme)")
        decisionHandler(.cancel)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // ✅ Сохраняем последний успешный URL
        if let currentURL = webView.url {
            SaveService.lastUrl = currentURL
            print("💾 Сохранён последний успешный URL: \(currentURL.absoluteString)")
        }
    }
    
    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        handleError(error, currentURL: webView.url)
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        handleError(error, currentURL: webView.url)
    }
    
    private func handleError(_ error: Error, currentURL: URL?) {
        let nsError = error as NSError
        print("❌ Ошибка загрузки: \(nsError.code) — \(nsError.localizedDescription)")
        
        // Обрабатываем слишком большое число редиректов
        if nsError.code == NSURLErrorHTTPTooManyRedirects {
            guard redirectRetryCount < maxRetryCount else {
                print("⚠️ Превышено количество повторных попыток после редиректов")
                return
            }
            
            redirectRetryCount += 1
            print("🔄 Повторная загрузка после ERR_TOO_MANY_REDIRECTS (\(redirectRetryCount))")
            
            let urlToReload = currentURL ?? startURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.loadURL(urlToReload)
            }
        }
    }
}



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
