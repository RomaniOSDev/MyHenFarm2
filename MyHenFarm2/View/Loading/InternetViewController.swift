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
        presentSafariViewController()
    }
    
    private func presentSafariViewController() {
        let safariVC = SFSafariViewController(url: termsURL)
        safariVC.preferredBarTintColor = UIColor.black
        safariVC.preferredControlTintColor = UIColor.white
        safariVC.modalPresentationStyle = .fullScreen
        
        present(safariVC, animated: true)
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