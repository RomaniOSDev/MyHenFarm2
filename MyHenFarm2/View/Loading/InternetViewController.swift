

import UIKit
import WebKit


class WebviewVC: UIViewController, WKNavigationDelegate {
    
    private var webView: WKWebView!
    private let startURL: URL
    
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
            
            // Проверяем и нормализуем
            if let safe = safeURL(from: clickedURL.absoluteString) {
                decisionHandler(.cancel) // отменяем стандартный переход
                loadURL(safe)            // загружаем заново
                return
            } else {
                print("⚠️ Не удалось создать URL из: \(clickedURL.absoluteString)")
            }
        }
        
        decisionHandler(.allow)
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
