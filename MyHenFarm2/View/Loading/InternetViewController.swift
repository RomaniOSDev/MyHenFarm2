import UIKit
import WebKit

final class WebviewVC: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private let startURL: URL
    private var progressView: UIProgressView!
    private var checkTask: URLSessionDataTask?

    // Храним последний URL из цепочки
    private var lastCheckedURL: URL?

    init(url: URL) {
        self.startURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) не используется") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeProgress()
        loadURL(startURL)
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // ✅ Свайп-навигация и предпросмотр ссылок
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true

        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.tintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(progressView)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func observeProgress() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?,
                                of object: Any?,
                                change: [NSKeyValueChangeKey : Any]?,
                                context: UnsafeMutableRawPointer?) {
        guard keyPath == "estimatedProgress" else { return }
        progressView.isHidden = false
        progressView.progress = Float(webView.estimatedProgress)
        if webView.estimatedProgress >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.progressView.isHidden = true
                self?.progressView.progress = 0
            }
        }
    }

    private func loadURL(_ url: URL) {
        print("🌍 Загружаем: \(url.absoluteString)")
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Проверяем только клики
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            progressView.isHidden = false
            progressView.progress = 0.1

            checkRedirects(for: url) { [weak self] result in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    switch result {
                    case .success(let finalURL):
                        print("✅ Проверка пройдена, загружаем \(finalURL)")
                        self.loadURL(finalURL)
                    case .failure(let error):
                        print("❌ Ошибка при проверке: \(error.localizedDescription)")
                        self.showRedirectAlert(for: url)
                    }
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }

    // MARK: - Redirect Checking
    private func checkRedirects(for url: URL,
                                attempt: Int = 1,
                                maxAttempts: Int = 5,
                                completion: @escaping (Result<URL, Error>) -> Void) {
        lastCheckedURL = url

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let session = URLSession(configuration: .ephemeral)
        checkTask?.cancel()

        checkTask = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }

            if let error = error as NSError?,
               error.code == NSURLErrorHTTPTooManyRedirects {
                print("⚠️ ERR_TOO_MANY_REDIRECTS на \(url)")

                if attempt < maxAttempts {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // 🔁 Пробуем снова с тем же URL (не с последним успешным)
                        self.checkRedirects(for: url, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.clearCookies()
                        completion(.success(self.lastCheckedURL ?? url))
                    }
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               (300...399).contains(httpResponse.statusCode),
               let location = httpResponse.allHeaderFields["Location"] as? String,
               let redirectURL = URL(string: location, relativeTo: url) {
                print("➡️ Redirect: \(redirectURL)")
                self.lastCheckedURL = redirectURL
                self.checkRedirects(for: redirectURL, attempt: attempt, completion: completion)
                return
            }

            DispatchQueue.main.async {
                completion(.success(self.lastCheckedURL ?? url))
            }
        }

        checkTask?.resume()
    }

    // MARK: - Очистка cookies
    private func clearCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                print("🧹 Cookies очищены")
            }
        }
    }

    // MARK: - Alert
    private func showRedirectAlert(for url: URL) {
        let alert = UIAlertController(
            title: "Ошибка загрузки",
            message: "Слишком много перенаправлений при попытке открыть:\n\(url.absoluteString)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Redirect Detector
private final class RedirectDetectorDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        // разрешаем максимум 20 редиректов (система отлавливает сама)
        completionHandler(request)
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
