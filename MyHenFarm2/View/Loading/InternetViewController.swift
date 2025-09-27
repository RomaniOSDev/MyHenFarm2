import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate {
    
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
        
        // Disable zoom: inject viewport meta and block pinch gesture
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
        
        // Block pinch zoom at UIScrollView level as well
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        return webView
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
        loadInitialURL()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(firemanWebviewForTerms)
        firemanWebviewForTerms.allowsBackForwardNavigationGestures = true
        
        NSLayoutConstraint.activate([
            firemanWebviewForTerms.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            firemanWebviewForTerms.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            firemanWebviewForTerms.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            firemanWebviewForTerms.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadInitialURL() {
        firemanWebviewForTerms.load(URLRequest(url: termsURL))
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
        
        // Обрабатываем кастомные deeplink'и (замените на ваши схемы)
        if urlString.hasPrefix("myapp://") ||
           urlString.hasPrefix("yourapp://") ||
           urlString.hasPrefix("appname://") {
            
            print("Deeplink detected: \(urlString)")
            handleDeepLink(url)
            decisionHandler(.cancel)
            return
        }
        
        // Разрешаем обычные HTTP/HTTPS запросы
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
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
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
        
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
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
    }
    
    // MARK: - DeepLink Handling
    private func handleDeepLink(_ url: URL) {
        print("Processing deeplink: \(url)")
        
        // Здесь добавьте вашу логику обработки deeplink'ов
        // Например:
        // - Закрыть webview
        // - Перейти на другой экран
        // - Выполнить какое-то действие в приложении
        
        let urlString = url.absoluteString
        print("Deeplink URL: \(urlString)")
        
        // Пример обработки различных deeplink'ов
        if urlString.contains("success") {
            // Обработка успешного сценария
            print("Success deeplink detected")
        } else if urlString.contains("cancel") {
            // Обработка отмены
            print("Cancel deeplink detected")
        }
        
        // Если нужно закрыть webview после обработки deeplink'а:
        // self.dismiss(animated: true)
        // или
        // self.navigationController?.popViewController(animated: true)
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
