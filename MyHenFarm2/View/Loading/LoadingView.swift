//
//  LoadingView.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//

import UIKit
import SwiftUI
import AppTrackingTransparency
import AdSupport
import Network

// MARK: - Loading States
enum LoadingState {
    case initial
    case loading
    case success(String)
    case error(String)
}

// MARK: - Loading View Controller
class LoadingView: UIViewController {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let loadingImageView = UIImageView()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private lazy var consoleHosting: UIViewController = {
        let host = UIHostingController(rootView: BottomConsoleView())
        host.view.backgroundColor = .clear
        return host
    }()
    
    
    // MARK: - Properties
    private var currentState: LoadingState = .initial {
        didSet {
            updateUI(for: currentState)
        }
    }
    
    private let networkManager: NetworkManager
    private let appsFlyerManager: AppsFlyerManager
    private var appsFlyerData: [String: Any?] = [:]
    private let additionalData: [String: Any]
    
    private var conversionRetryCount = 0
    private var isConversionDataReceived = false
    
    // MARK: - Initialization
    init(networkManager: NetworkManager, 
         appsFlyerManager: AppsFlyerManager,
         additionalData: [String: Any]) {
        self.networkManager = networkManager
        self.appsFlyerManager = appsFlyerManager
        self.additionalData = additionalData
        super.init(nibName: nil, bundle: nil)
    }
    
    // Convenience initializer
    convenience init() {
        let networkManager = NetworkManager(configuration: AppParameters.networkConfiguration)
        let appsFlyerManager = AppsFlyerManager(devKey: AppParameters.appsFlyerDevKey, appID: AppParameters.appsFlyerAppID)
        self.init(
            networkManager: networkManager,
            appsFlyerManager: appsFlyerManager,
            additionalData: AppParameters.requiredParameters
        )
    }
    
    required init?(coder: NSCoder) {
        let networkManager = NetworkManager(configuration: AppParameters.networkConfiguration)
        let appsFlyerManager = AppsFlyerManager(devKey: AppParameters.appsFlyerDevKey, appID: AppParameters.appsFlyerAppID)
        self.networkManager = networkManager
        self.appsFlyerManager = appsFlyerManager
        self.additionalData = AppParameters.requiredParameters
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        // ATT запрос покажем в viewDidAppear, чтобы окно точно было на экране
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestTrackingIfNeeded { [weak self] in
            self?.checkInternet { hasInternet in
                if hasInternet {
                    self?.startLoadingProcess()
                } else {
                    self?.presentNoInternetAlert()
                }
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Container view for better organization
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Loading image
        loadingImageView.image = UIImage(named: "logo")
        loadingImageView.contentMode = .scaleAspectFit
        loadingImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingImageView)
        
        // Activity indicator
        containerView.addSubview(activityIndicator)

        // Bottom console host
        addChild(consoleHosting)
        view.addSubview(consoleHosting.view)
        consoleHosting.didMove(toParent: self)
        
        // Add gradient overlay for better text readability
        addGradientOverlay()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading image
            loadingImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            loadingImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loadingImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            loadingImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Bottom console constraints
            consoleHosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            consoleHosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            consoleHosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            consoleHosting.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    private func addGradientOverlay() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        view.layer.addSublayer(gradientLayer)
        
        // Bring UI elements to front
        view.bringSubviewToFront(containerView)
    }
    
    // MARK: - Loading Process
    private func startLoadingProcess() {
        currentState = .loading
        getAppsFlyerData()
    }

    // MARK: - Test Action (removed)
    
    // MARK: - ATT
    private func requestTrackingIfNeeded(completion: @escaping () -> Void) {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            switch status {
            case .notDetermined:
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async { completion() }
                }
            default:
                completion()
            }
        } else {
            completion()
        }
    }

    // MARK: - Internet Check
    private func checkInternet(completion: @escaping (Bool) -> Void) {
        if #available(iOS 12.0, *) {
            let monitor = NWPathMonitor()
            let queue = DispatchQueue.global(qos: .background)
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                DispatchQueue.main.async {
                    completion(path.status == .satisfied)
                }
            }
            monitor.start(queue: queue)
        } else {
            // Fallback: считаем, что интернет есть
            completion(true)
        }
    }

    private func presentNoInternetAlert() {
        let alert = UIAlertController(title: "Нет подключения", message: "Проверьте интернет-соединение и повторите попытку.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Настройки", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { [weak self] _ in
            self?.checkInternet { hasInternet in
                if hasInternet {
                    self?.startLoadingProcess()
                } else {
                    self?.presentNoInternetAlert()
                }
            }
        }))
        present(alert, animated: true)
    }
    
    
    private func getAppsFlyerData() {
        print("getting conversion data...")
        ConsoleLogger.shared.log("AF: requesting conversion data…")
        let appsFlyerTimeout = DispatchTime.now() + 10.0
        
        appsFlyerManager.getConversionData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conversionData):
                    print("Conversion data received: \(conversionData)")
                    self?.appsFlyerData = conversionData
                    self?.isConversionDataReceived = true
                    let afStatus = (conversionData["af_status"] as? String) ?? "<nil>"
                    let keys = Array(conversionData.keys).sorted().joined(separator: ", ")
                    ConsoleLogger.shared.log("AF: conversion received, af_status=\(afStatus), keys=[\(keys)]")
                    self?.checkConversionStatusAndProceed(conversionData)
                    
                case .failure(let error):
                    print("Failed to get conversion data: \(error.localizedDescription)")
                    ConsoleLogger.shared.log("AF: conversion error → \(error.localizedDescription)")
                    self?.currentState = .error("Ошибка AppsFlyer: \(error.localizedDescription)")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: appsFlyerTimeout) { [weak self] in
            guard let self = self else { return }
            if !self.isConversionDataReceived {
                let timeoutError = NSError(domain: "AppsFlyer", code: 2002, userInfo: [NSLocalizedDescriptionKey: "Timeout AppsFlyer "])
                ConsoleLogger.shared.log("AF: conversion timeout")
                self.handleError(timeoutError)
            }
        }
    }
    
    private func checkConversionStatusAndProceed(_ conversionData: [String: Any?]) {
        if let afStatus = conversionData["af_status"] as? String {
            if afStatus == "Organic" && conversionRetryCount == 0 {
                conversionRetryCount = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    ConsoleLogger.shared.log("AF: Organic (retry once)…")
                    self?.retryConversionDataRequest()
                }
            } else if afStatus == "Organic" && conversionRetryCount == 1 {
                print("I'm organic")
                ConsoleLogger.shared.log("AF: Organic → go to ContentView")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.navigateToContentView()
                }
            } else {
                conversionRetryCount = 0
                ConsoleLogger.shared.log("AF: Non-organic → sendNetworkRequest()")
                sendNetworkRequest()
            }
        } else {
            ConsoleLogger.shared.log("AF: af_status missing → sendNetworkRequest()")
            sendNetworkRequest()
        }
    }
    
    private func retryConversionDataRequest() {
        appsFlyerManager.getConversionData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newConversionData):
                    self?.appsFlyerData = newConversionData
                    self?.isConversionDataReceived = true
                    self?.checkConversionStatusAndProceed(newConversionData)
                    
                case .failure(let error):
                    self?.currentState = .error("Error AppsFlyer: \(error.localizedDescription)")
                }
            }
        }
    }
    

    private func sendNetworkRequest() {
        ConsoleLogger.shared.log("NET: sending conversion to server…")
        networkManager.sendConversionData(
            appsFlyerData: appsFlyerData,
            additionalData: additionalData
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleNetworkResult(result)
            }
        }
    }
    

    private func handleNetworkResult(_ result: Result<Data, NSError>) {
        switch result {
        case .success(let data):
            handleSuccessResponse(data)
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleSuccessResponse(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                currentState = .error("bad format")
                return
            }
            
            // Логирование ответа сервера
            print("📥 Server Response:")
            if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                ConsoleLogger.shared.log("NET: response\n\(jsonString)")
            }
            
            guard let status = json["ok"] as? Bool, status == true else {
                let message = json["message"] as? String ?? "Server error"
                print("❌ Server error: \(message)")
                ConsoleLogger.shared.log("NET: server error → \(message)")
                currentState = .error(message)
                return
            }

            guard let urlString = json["url"] as? String, !urlString.isEmpty else {
                print("❌ URL not found in response")
                ConsoleLogger.shared.log("NET: url not found in response")
                currentState = .error("URL not found")
                return
            }
            
            print("✅ Success! URL received: \(urlString)")
            ConsoleLogger.shared.log("NET: success, url=\(urlString)")
            SaveService.lastUrl = URL(string: urlString)
            
            if let expiresString = json["expires"] as? String, !expiresString.isEmpty {
                print("⏰ Expires: \(expiresString)")
                ConsoleLogger.shared.log("NET: expires=\(expiresString)")
                SaveService.time = expiresString
            }
            
            currentState = .success(urlString)
        } catch {
            print("❌ JSON parsing error: \(error.localizedDescription)")
            ConsoleLogger.shared.log("NET: JSON parsing error → \(error.localizedDescription)")
            currentState = .error("error parsing JSON: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: NSError) {
        ConsoleLogger.shared.log("NET: error code=\(error.code) desc=\(error.localizedDescription)")

        switch error.code {
        case 2001: // AppsFlyer conversion data error
            currentState = .error("Error AppsFlyer: \(error.localizedDescription)")
        case 2002: // AppsFlyer timeout
            currentState = .error("Timeout AppsFlyer: \(error.localizedDescription)")
        case 1001: // invalidURL
            currentState = .error("Bad URL")
        case 1002: // encodingError
            currentState = .error("error decoding: \(error.localizedDescription)")
        case 1003: // invalidResponse
            currentState = .error("Неверный ответ сервера")
        case 1004: // noData
            currentState = .error("Нет данных в ответе")
        case 400: // badRequest
            currentState = .error("Неверный запрос (400)")
        case 401: // unauthorized
            currentState = .error("Не авторизован (401)")
        case 403: // forbidden
            currentState = .error("Доступ запрещен (403)")
        case 404: // notFound
            currentState = .error("Ресурс не найден (404)")
        case 429: // rateLimited
            currentState = .error("Превышен лимит запросов (429)")
        case NSURLErrorTimedOut: // timeout
            currentState = .error("Превышено время ожидания")
        case NSURLErrorNotConnectedToInternet: // noInternetConnection
            currentState = .error("Нет подключения к интернету")
        case NSURLErrorCannotConnectToHost: // cannotConnectToHost
            currentState = .error("Не удается подключиться к серверу")
        case 500..<600: // serverError
            currentState = .error("Ошибка сервера: \(error.code)")
        default:
            currentState = .error("Ошибка сети: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UI Updates
    private func updateUI(for state: LoadingState) {
        switch state {
        case .initial:
            break
            
        case .loading:
            activityIndicator.startAnimating()
            
        case .success(let url):
            activityIndicator.stopAnimating()
            
            // Delay before navigation to show success state (ok = true, URL exists)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.navigateToWebView(url: url)
            }
            
        case .error(_):
            activityIndicator.stopAnimating()
            // Delay before navigation to show error state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.navigateToContentView()
            }
        }
    }
    
    
    
    
   
    
    // MARK: - Navigation
    private func navigateToWebView(url: String) {
        guard let webURL = URL(string: url) else {
            navigateToContentView()
            return
        }
        
        // Показываем экран разрешения уведомлений перед WebView
        let notificationView = NotificationPermissionView(webURL: webURL)
        let hostingController = UIHostingController(rootView: notificationView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
    
    private func navigateToContentView() {
        let swiftUIView = ContentView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
}


