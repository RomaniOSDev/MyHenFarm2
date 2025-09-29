import UIKit
import WebKit

class CoreViewController: UIViewController {
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private lazy var upperView: UIView = {
        let view = UIView()
        let darkColor = UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.0)
        view.backgroundColor = darkColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private(set) lazy var backButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.setBackgroundImage(UIImage(systemName: "arrow.left.circle"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let urlString: URL
    
    init(url: URL) {
        self.urlString = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadURL()
    }
    
    private func setupViews() {
        view.addSubview(webView)
        view.addSubview(upperView)
        upperView.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: upperView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            upperView.topAnchor.constraint(equalTo: view.topAnchor),
            upperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            upperView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            upperView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 34)
        ])
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.bottomAnchor.constraint(equalTo: upperView.bottomAnchor, constant: -5),
            backButton.heightAnchor.constraint(equalToConstant: 30),
            backButton.widthAnchor.constraint(equalToConstant: 30)
            
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTap), for: .touchUpInside)
        
    }
    @objc private func backButtonTap() {
        if webView.canGoBack{
            webView.goBack()
        }
    }
    private func loadURL() {
       
        let request = URLRequest(url: urlString)
        webView.load(request)
        
    }

}
