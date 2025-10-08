import UIKit
import WebKit

class WebviewVC: UIViewController, WKNavigationDelegate {

    private var progressView: UIProgressView!
    private var progressObservation: NSKeyValueObservation?
    private var isChecking = false
    private let maxRedirectRetries = 3

    lazy var firemanWebviewForTerms: WKWebView = {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    private let termsURL: URL
    
    init(url: URL) {
        self.termsURL = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialPage()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 1️⃣ Добавляем webView
        view.addSubview(firemanWebviewForTerms)
        NSLayoutConstraint.activate([
            firemanWebviewForTerms.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            firemanWebviewForTerms.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            firemanWebviewForTerms.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            firemanWebviewForTerms.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 2️⃣ Добавляем progress bar
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.trackTintColor = .clear
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        // 3️⃣ Наблюдаем за прогрессом webView
        progressObservation = firemanWebviewForTerms.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let progress = change.newValue else { return }
            DispatchQueue.main.async {
                self?.updateProgressBar(progress)
            }
        }
    }

    private func loadInitialPage() {
        let request = URLRequest(url: termsURL)
        firemanWebviewForTerms.load(request)
    }

    private func updateProgressBar(_ progress: Double) {
        progressView.alpha = 1
        progressView.setProgress(Float(progress), animated: true)
        
        if progress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut) {
                self.progressView.alpha = 0
            } completion: { _ in
                self.progressView.progress = 0
            }
        }
    }

    // MARK: - Навигация и проверка ссылок
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Проверяем только реальные клики по ссылкам
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            checkRedirect(for: url)
        } else {
            decisionHandler(.allow)
        }
    }

    // ✅ Проверка URL на редирект
    private func checkRedirect(for url: URL, attempt: Int = 1) {
        guard !isChecking else { return }
        isChecking = true
        showProgress(true)

        print("🧭 Проверка (\(attempt)): \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showProgress(false)
            }
            self.isChecking = false
            
            if let error = error as? URLError, error.code == .httpTooManyRedirects {
                if attempt < self.maxRedirectRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.checkRedirect(for: url, attempt: attempt + 1)
                    }
                } else {
                    self.showRedirectAlert(for: url)
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                print("📡 Статус ответа: \(status)")
                
                if (200..<300).contains(status) {
                    DispatchQueue.main.async {
                        self.firemanWebviewForTerms.load(URLRequest(url: url))
                    }
                } else if (300..<400).contains(status) {
                    if attempt < self.maxRedirectRetries {
                        self.checkRedirect(for: url, attempt: attempt + 1)
                    } else {
                        self.showRedirectAlert(for: url)
                    }
                } else {
                    self.showRedirectAlert(for: url)
                }
            } else {
                self.showRedirectAlert(for: url)
            }
        }.resume()
    }

    private func showProgress(_ visible: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.progressView.alpha = visible ? 1 : 0
            }
        }
    }

    private func showRedirectAlert(for url: URL) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Похоже, ссылка вызывает слишком много редиректов:\n\(url.absoluteString)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
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
