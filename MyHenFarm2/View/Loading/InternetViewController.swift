import UIKit
import WebKit

final class WebviewVC: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private let startURL: URL
    private var progressView: UIProgressView!
    private let maxRedirectChecks = 3

    // MARK: - Init
    init(url: URL) {
        self.startURL = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) не используется") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupProgressView()
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
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func showProgress(_ show: Bool) {
        DispatchQueue.main.async {
            self.progressView.isHidden = !show
            if show {
                self.progressView.setProgress(0.3, animated: false)
                UIView.animate(withDuration: 1.0) {
                    self.progressView.setProgress(0.9, animated: true)
                }
            } else {
                self.progressView.setProgress(0.0, animated: false)
            }
        }
    }

    // MARK: - URL Loading
    private func loadURL(_ url: URL) {
        print("➡️ Загружаем страницу: \(url.absoluteString)")
        webView.load(URLRequest(url: url))
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Проверяем каждый переход, включая клики и редиректы внутри страницы
        print("🔗 Проверка перехода: \(url.absoluteString)")
        decisionHandler(.cancel)
        checkRedirect(for: url)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Успешно загружено: \(webView.url?.absoluteString ?? "")")
        showProgress(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showProgress(false)
        print("❌ Ошибка навигации: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showProgress(false)
        print("❌ Ошибка provisionalNavigation: \(error.localizedDescription)")
    }

    // MARK: - Redirect check
    private func checkRedirect(for url: URL, attempt: Int = 1) {
        showProgress(true)
        print("🧭 Проверяем URL (\(attempt)) → \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config,
                                 delegate: RedirectDetectingDelegate(),
                                 delegateQueue: nil)

        let task = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }

            if let error = error as? URLError, error.code == .httpTooManyRedirects {
                print("⚠️ Цикл редиректов обнаружен")
                if attempt < self.maxRedirectChecks {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.checkRedirect(for: url, attempt: attempt + 1)
                    }
                } else {
                    self.showRedirectAlert(for: url)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Нет корректного HTTP-ответа")
                self.showRedirectAlert(for: url)
                return
            }

            if (200..<400).contains(httpResponse.statusCode) {
                print("✅ Проверка успешна, статус \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    self.loadURL(url)
                }
            } else {
                print("⚠️ Неуспешный статус: \(httpResponse.statusCode)")
                self.showRedirectAlert(for: url)
            }

            DispatchQueue.main.async {
                self.showProgress(false)
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

// MARK: - Redirect detector delegate
private final class RedirectDetectingDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request) // позволяем максимум 20 редиректов
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
