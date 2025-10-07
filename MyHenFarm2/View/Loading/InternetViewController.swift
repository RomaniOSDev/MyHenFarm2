import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate {
    
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
    
    private func loadURL(_ url: URL) {
        print("➡️ Загружаем: \(url.absoluteString)")
        let request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 30)
        webView.load(request)
    }
    
    // MARK: - Helper для нормализации ссылок
    private func safeURL(from raw: String) -> URL? {
        if let url = URL(string: raw) {
            return url
        }
        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encoded)
        }
        return nil
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if navigationAction.navigationType == .linkActivated,
           let clickedURL = navigationAction.request.url {
            
            print("🔗 Клик по ссылке: \(clickedURL.absoluteString)")
            
            if let safe = safeURL(from: clickedURL.absoluteString) {
                decisionHandler(.cancel)
                loadURL(safe)
                return
            } else {
                print("⚠️ Не удалось создать URL из: \(clickedURL.absoluteString)")
            }
        }
        
        decisionHandler(.allow)
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
    
    // MARK: - Обработка ошибок
    private func handleError(_ error: Error, currentURL: URL?) {
        let nsError = error as NSError
        print("❌ Ошибка загрузки: \(nsError.code) — \(nsError.localizedDescription)")
        
        // Проверяем на ERR_TOO_MANY_REDIRECTS
        if nsError.code == NSURLErrorHTTPTooManyRedirects {
            guard redirectRetryCount < maxRetryCount else {
                print("⚠️ Превышено количество повторных попыток после редиректов")
                return
            }
            
            redirectRetryCount += 1
            print("🔄 Повторная загрузка после ERR_TOO_MANY_REDIRECTS (\(redirectRetryCount))")
            
            if let url = currentURL ?? startURL as URL? {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.loadURL(url)
                }
            }
        }
    }
}
