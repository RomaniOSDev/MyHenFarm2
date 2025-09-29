

import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var currentURL: URL

    // счётчик редиректов
    private var redirectCount = 0
    private let maxRedirects = 5

    init(url: URL) {
        self.currentURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        loadURL(currentURL)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }

    private func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        redirectCount = 0
        webView.load(request)
    }

    /// Полный сброс и загрузка нового URL
    func openNewURL(_ url: URL) {
        webView.removeFromSuperview()
        webView.navigationDelegate = nil
        webView = nil

        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                print("🗑️ Cookies & Cache очищены")
            }
        }

        setupWebView()
        currentURL = url
        loadURL(url)
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            print("👆 Клик по ссылке: \(url.absoluteString)")
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        // каждый новый ответ можно считать редиректом
        redirectCount += 1
        print("➡️ Редирект #\(redirectCount): \(webView.url?.absoluteString ?? "")")

        if redirectCount > maxRedirects {
            if let finalURL = webView.url {
                print("❌ Слишком много редиректов. Перезапускаем загрузку: \(finalURL)")
                decisionHandler(.cancel)
                openNewURL(finalURL)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Загружено: \(webView.url?.absoluteString ?? "")")
        redirectCount = 0 // сбрасываем после успешной загрузки
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Ошибка: \(error.localizedDescription)")
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
