//
//  PreloadedSafariVC.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 08.10.2025.
//

import UIKit
import WebKit
import SafariServices

final class PreloadedSafariVC: UIViewController, WKNavigationDelegate {

    private let startURL: URL
    private var webView: WKWebView!
    private var finalURL: URL?
    private var redirectTimer: Timer?

    init(url: URL) {
        self.startURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) не используется") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHiddenWebView()
        preloadFinalURL()
    }

    private func setupHiddenWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true // не показываем пользователю
        view.addSubview(webView)
    }

    private func preloadFinalURL() {
        print("🌐 Предзагрузка: \(startURL.absoluteString)")
        webView.load(URLRequest(url: startURL))
        
        // таймер, если редиректы затянулись
        redirectTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("⏱️ Тайм-аут предзагрузки, открываем текущий URL")
            self.openInSafari(url: self.finalURL ?? self.startURL)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let current = webView.url else { return }
        print("✅ Загружено: \(current.absoluteString)")
        finalURL = current
        
        // небольшая задержка для финального редиректа
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if current == self.webView.url {
                self.redirectTimer?.invalidate()
                self.openInSafari(url: current)
            }
        }
    }

    private func openInSafari(url: URL) {
        print("🚀 Открываем в Safari: \(url.absoluteString)")
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .systemBlue
        safariVC.dismissButtonStyle = .close
        present(safariVC, animated: true)
    }
}
