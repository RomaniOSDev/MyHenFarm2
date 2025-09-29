import UIKit
import SafariServices

class WebviewVC: UIViewController {
    
    // MARK: - Properties
    let termsURL: URL
    
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
        view.backgroundColor = .white
        presentSafariViewController()
    }
    
    private func presentSafariViewController() {
        let safariVC = SFSafariViewController(url: termsURL)
        safariVC.preferredBarTintColor = UIColor.black
        safariVC.preferredControlTintColor = UIColor.white
        safariVC.modalPresentationStyle = .fullScreen
        
        // Добавляем Safari как child view controller
        addChild(safariVC)
        view.addSubview(safariVC.view)
        safariVC.view.frame = view.bounds
        safariVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        safariVC.didMove(toParent: self)
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