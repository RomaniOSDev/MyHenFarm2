import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    // MARK: - Properties
    let termsURL: URL
    
    // MARK: - UI Components
    lazy var firemanWebviewForTerms: WKWebView = {
        let privacyConfiguration = WKWebViewConfiguration()
        privacyConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        privacyConfiguration.allowsPictureInPictureMediaPlayback = true
        privacyConfiguration.allowsAirPlayForMediaPlayback = true
        privacyConfiguration.allowsInlineMediaPlayback = true
        privacyConfiguration.preferences.javaScriptEnabled = true
        privacyConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Disable zoom
        let userContentController = WKUserContentController()
        let disableZoomScript = """
        (function() {
          var meta = document.querySelector('meta[name=viewport]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
          }
          meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
          document.addEventListener('gesturestart', function (e) { e.preventDefault(); }, { passive: false });
        })();
        """
        userContentController.addUserScript(WKUserScript(source: disableZoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        privacyConfiguration.userContentController = userContentController
        
        let privacyPreferences = WKWebpagePreferences()
        privacyPreferences.preferredContentMode = .mobile
        privacyConfiguration.defaultWebpagePreferences = privacyPreferences
        
        let webView = WKWebView(frame: .zero, configuration: privacyConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Block pinch zoom
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        return webView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(url: URL) {
        self.termsURL = url
        print("termsURL: \(termsURL)")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        obtainCookies()
        firemanWebviewForTerms.navigationDelegate = self
        firemanWebviewForTerms.uiDelegate = self
        loadInitialURL()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(firemanWebviewForTerms)
        view.addSubview(activityIndicator)
        
        firemanWebviewForTerms.allowsBackForwardNavigationGestures = true
        
        NSLayoutConstraint.activate([
            firemanWebviewForTerms.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            firemanWebviewForTerms.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            firemanWebviewForTerms.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            firemanWebviewForTerms.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadInitialURL() {
        activityIndicator.startAnimating()
        
        // 1) Очистим фрагмент из URL (убираем #:~:text и т.п.)
        var components = URLComponents(url: termsURL, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        let cleanURL = components?.url ?? termsURL
        let targetHost = cleanURL.host ?? ""
        
        // 2) Очистим куки для домена и кэш перед загрузкой
        let store = WKWebsiteDataStore.default()
        store.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies where cookie.domain.contains(targetHost) {
                store.httpCookieStore.delete(cookie)
            }
            let types: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
            WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) { [weak self] in
                guard let self = self else { return }
                
                // Создаем запрос с правильными заголовками
                var request = URLRequest(url: cleanURL)
                request.timeoutInterval = 30
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                // Добавляем User-Agent для мобильного устройства
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
                
                self.firemanWebviewForTerms.load(request)
            }
        }
    }
    
    // MARK: - Cookie Management
    func obtainCookies() {
        let standardStorage: UserDefaults = UserDefaults.standard
        let data: Data? = standardStorage.object(forKey: "cvcvcv") as? Data
        if let cookie = data {
            let datas: NSArray? = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: cookie)
            if let cookies = datas {
                for c in cookies {
                    if let cookieObject = c as? HTTPCookie {
                        HTTPCookieStorage.shared.setCookie(cookieObject)
                    }
                }
            }
        }
    }
    
    private func saveCookies() {
        let cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieJar.cookies {
            let data: Data? = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)
            if let data = data {
                let userDefaults = UserDefaults.standard
                userDefaults.set(data, forKey: "cvcvcv")
            }
        }
    }
    
    
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        saveCookies()
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = url.absoluteString
        print("Navigation attempt to: \(urlString)")
        print("Navigation type: \(navigationAction.navigationType.rawValue)")
        
        // Проверяем, является ли ссылка той самой проблемной
        if urlString.contains("test-web.syndi-test.net") {
            print("🔗 Обнаружена целевая ссылка: \(urlString)")
            
            // Декодируем URL для лучшей читаемости
            if let decodedString = urlString.removingPercentEncoding {
                print("🔗 Декодированная ссылка: \(decodedString)")
            }
        }
        
        // Блокируем опасные схемы
        if urlString.hasPrefix("file://") ||
           urlString.hasPrefix("javascript:") {
            print("Blocked dangerous scheme: \(urlString)")
            decisionHandler(.cancel)
            return
        }
        
        // Обрабатываем системные схемы
        if urlString.hasPrefix("tel:") ||
           urlString.hasPrefix("mailto:") ||
           urlString.hasPrefix("sms:") ||
           urlString.hasPrefix("facetime:") {
            
            print("Opening system URL: \(urlString)")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
            return
        }
        
        // Обрабатываем кастомные deeplink'и
        if urlString.hasPrefix("myapp://") ||
           urlString.hasPrefix("yourapp://") ||
           urlString.hasPrefix("appname://") {
            
            print("Deeplink detected: \(urlString)")
            handleDeepLink(url)
            decisionHandler(.cancel)
            return
        }
        
        // Разрешаем обычные HTTP/HTTPS запросы в WebView
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            print("🌐 Loading URL in WebView: \(urlString)")
            decisionHandler(.allow)
            return
        }
        
        // Для всех остальных случаев
        print("Allowing navigation to: \(urlString)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Открываем ссылки с target="_blank" в текущем webview
        if navigationAction.targetFrame == nil {
            print("Opening target=_blank link: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView started loading")
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
        activityIndicator.stopAnimating()
        
        if let url = webView.url {
            print("Current webview URL: \(url)")
            
            if SaveService.lastUrl == nil {
                SaveService.lastUrl = url
                print("Saved last url: \(String(describing: SaveService.lastUrl))")
            }
        }
        
        // Проверяем сохраненную дату expires
        if let savedTime = SaveService.time {
            print("Сохраненная дата expires: \(savedTime)")
        } else {
            print("Дата expires не найдена")
        }
        
        // Добавляем JavaScript для отладки кликов
        let clickDebugScript = """
        // Добавляем обработчики ко всем ссылкам
        document.addEventListener('click', function(e) {
            if (e.target.tagName === 'A' || e.target.closest('a')) {
                const link = e.target.tagName === 'A' ? e.target : e.target.closest('a');
                console.log('Clicked link:', link.href);
                console.log('Link target:', link.target);
                console.log('Link text:', link.textContent);
            }
        }, true);
        
        // Логируем все ссылки на странице
        const links = document.getElementsByTagName('a');
        console.log('Total links on page:', links.length);
        for (let i = 0; i < links.length; i++) {
            console.log('Link ' + i + ':', links[i].href, 'target:', links[i].target);
        }
        """
        
        webView.evaluateJavaScript(clickDebugScript) { result, error in
            if let error = error {
                print("Error injecting debug script: \(error)")
            } else {
                print("Debug script injected successfully")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
        activityIndicator.stopAnimating()
        // Показываем ошибку пользователю
        showErrorAlert(message: error.localizedDescription)
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка загрузки",
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { _ in
            self.reload()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - DeepLink Handling
    private func handleDeepLink(_ url: URL) {
        print("Processing deeplink: \(url)")
        
        let urlString = url.absoluteString
        print("Deeplink URL: \(urlString)")
        
        // Пример обработки различных deeplink'ов
        if urlString.contains("success") {
            print("Success deeplink detected")
        } else if urlString.contains("cancel") {
            print("Cancel deeplink detected")
        }
    }
    
    // MARK: - Utility Methods
    func goBack() {
        if firemanWebviewForTerms.canGoBack {
            firemanWebviewForTerms.goBack()
        }
    }
    
    func goForward() {
        if firemanWebviewForTerms.canGoForward {
            firemanWebviewForTerms.goForward()
        }
    }
    
    func reload() {
        firemanWebviewForTerms.reload()
    }
    
    func loadURL(_ url: URL) {
        firemanWebviewForTerms.load(URLRequest(url: url))
    }
}

// MARK: - SaveService Structure
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
