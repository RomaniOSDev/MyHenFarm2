//
//  SafariTabsVC.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 08.10.2025.
//

import SafariServices

final class SafariTabsVC: UIViewController {

    private let startURL: URL
    
    init(url: URL) {
        self.startURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не используется")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openInSafari()
    }

    private func openInSafari() {
        let safariVC = SFSafariViewController(url: startURL)
        safariVC.preferredControlTintColor = .systemBlue
        safariVC.dismissButtonStyle = .close
        present(safariVC, animated: true)
    }
}
