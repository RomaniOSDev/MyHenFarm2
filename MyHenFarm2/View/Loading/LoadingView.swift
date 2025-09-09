//
//  LoadingView.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//

import UIKit
import SwiftUI

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
        startLoadingProcess()
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
    
    
    private func getAppsFlyerData() {
        print("getting conversion data...")
        let appsFlyerTimeout = DispatchTime.now() + 10.0
        
        appsFlyerManager.getConversionData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conversionData):
                    print("Conversion data received: \(conversionData)")
                    self?.appsFlyerData = conversionData
                    self?.isConversionDataReceived = true
                    self?.checkConversionStatusAndProceed(conversionData)
                    
                case .failure(let error):
                    print("Failed to get conversion data: \(error.localizedDescription)")
                    self?.currentState = .error("Ошибка AppsFlyer: \(error.localizedDescription)")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: appsFlyerTimeout) { [weak self] in
            guard let self = self else { return }
            if !self.isConversionDataReceived {
                let timeoutError = NSError(domain: "AppsFlyer", code: 2002, userInfo: [NSLocalizedDescriptionKey: "Timeout AppsFlyer "])
                self.handleError(timeoutError)
            }
        }
    }
    
    private func checkConversionStatusAndProceed(_ conversionData: [String: Any?]) {
        if let afStatus = conversionData["af_status"] as? String {
            if afStatus == "Organic" && conversionRetryCount == 0 {
                conversionRetryCount = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.retryConversionDataRequest()
                }
            } else if afStatus == "Organic" && conversionRetryCount == 1 {
                print("I'm organic")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.navigateToContentView()
                }
            } else {
                conversionRetryCount = 0
                sendNetworkRequest()
            }
        } else {
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
            }
            
            guard let status = json["ok"] as? Bool, status == true else {
                let message = json["message"] as? String ?? "Server error"
                print("❌ Server error: \(message)")
                currentState = .error(message)
                return
            }

            guard let urlString = json["url"] as? String, !urlString.isEmpty else {
                print("❌ URL not found in response")
                currentState = .error("URL not found")
                return
            }
            
            print("✅ Success! URL received: \(urlString)")
            SaveService.lastUrl = URL(string: urlString)
            
            if let expiresString = json["expires"] as? String, !expiresString.isEmpty {
                print("⏰ Expires: \(expiresString)")
                SaveService.time = expiresString
            }
            
            currentState = .success(urlString)
        } catch {
            print("❌ JSON parsing error: \(error.localizedDescription)")
            currentState = .error("error parsing JSON: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: NSError) {

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


