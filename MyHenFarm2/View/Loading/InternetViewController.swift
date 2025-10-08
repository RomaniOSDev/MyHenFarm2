import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate {

    // MARK: - Properties
    private let termsURL: URL
    private var progressView: UIProgressView!
    private let maxRedirectRetries = 3
    private var isChecking = false

    // MARK: - Init
    init(url: URL) {
        self.termsURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - WebView setup
    lazy var firemanWebviewForTerms: WKWebView = {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .mobile
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        obtainCookies()
        loadInitialPage()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(firemanWebviewForTerms)

        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            firemanWebviewForTerms.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            firemanWebviewForTerms.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            firemanWebviewForTerms.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            firemanWebviewForTerms.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func showProgress(_ show: Bool) {
        DispatchQueue.main.async {
            self.progressView.isHidden = !show
            if show {
                self.progressView.setProgress(0.3, animated: false)
                UIView.animate(withDuration: 0.8) {
                    self.progressView.setProgress(0.9, animated: true)
                }
            } else {
                self.progressView.setProgress(0.0, animated: false)
            }
        }
    }

    // MARK: - Cookies
    private func obtainCookies() {
        if let data = UserDefaults.standard.object(forKey: "cvcvcv") as? Data,
           let cookiesArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) {
            for item in cookiesArray {
                if let cookie = item as? HTTPCookie {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
        }
    }

    private func saveCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "cvcvcv")
        }
    }

    // MARK: - Load
    private func loadInitialPage() {
        firemanWebviewForTerms.load(URLRequest(url: termsURL))
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        saveCookies()
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // проверяем только реальные клики, а не автопереходы
        if navigationAction.navigationType == .linkActivated {
            print("🔗 Проверяем перед переходом: \(url.absoluteString)")
            decisionHandler(.cancel)
            checkRedirect(for: url)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showProgress(false)
        if let url = webView.url {
            print("✅ Загружено: \(url)")
            if SaveService.lastUrl == nil {
                SaveService.lastUrl = url
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showProgress(false)
        print("❌ Ошибка: \(error.localizedDescription)")
    }

    // MARK: - Redirect Checking
    private func checkRedirect(for url: URL, attempt: Int = 1) {
        guard !isChecking else { return }
        isChecking = true
        showProgress(true)

        print("🧭 Проверка URL (\(attempt)): \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let session = URLSession(configuration: .default,
                                 delegate: RedirectDetectorDelegate(),
                                 delegateQueue: nil)

        let task = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            self.isChecking = false
            self.showProgress(false)

            if let error = error as? URLError, error.code == .httpTooManyRedirects {
                print("⚠️ Обнаружен цикл редиректов")
                if attempt < self.maxRedirectRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.checkRedirect(for: url, attempt: attempt + 1)
                    }
                } else {
                    self.showRedirectAlert(for: url)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Нет корректного ответа")
                self.showRedirectAlert(for: url)
                return
            }

            if (200..<400).contains(httpResponse.statusCode) {
                print("✅ Проверка прошла успешно (\(httpResponse.statusCode)) — загружаем страницу")
                DispatchQueue.main.async {
                    self.firemanWebviewForTerms.load(URLRequest(url: url))
                }
            } else {
                print("⚠️ Код статуса: \(httpResponse.statusCode)")
                self.showRedirectAlert(for: url)
            }
        }
        task.resume()
    }

    // MARK: - Alert
    private func showRedirectAlert(for url: URL) {
        DispatchQueue.main.async {
            self.showProgress(false)
            let alert = UIAlertController(
                title: "Ошибка загрузки",
                message: "Слишком много перенаправлений при попытке открыть:\n\(url.absoluteString)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Повторить", style: .default) { _ in
                self.checkRedirect(for: url)
            })
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
        }
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
