//
//  AppsFlyerManager.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//

import Foundation
import AppsFlyerLib


// MARK: - AppsFlyer Manager
class AppsFlyerManager: NSObject {
    
    // MARK: - Properties
    private let devKey: String
    private let appID: String
    private var conversionData: [String: Any?] = [:]
    private var isConversionDataReceived = false
    private var pendingCompletion: (([String: Any?]) -> Void)?
    private var pendingErrorCompletion: ((NSError) -> Void)?
    
    // MARK: - Initialization
    override init() {
        self.devKey = AppParameters.appsFlyerDevKey
        self.appID = AppParameters.appsFlyerAppID
        super.init()
        
        setupAppsFlyer()
    }
    
    init(devKey: String, appID: String) {
        self.devKey = devKey
        self.appID = appID
        super.init()

        setupAppsFlyer()
    }
    
    private func setupAppsFlyer() {
        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
    }
    
    // MARK: - Public Methods
    
    func getConversionData(completion: @escaping (Result<[String: Any?], NSError>) -> Void) {
        pendingCompletion = { conversionData in
            completion(.success(conversionData))
        }
        pendingErrorCompletion = { error in
            completion(.failure(error))
        }

        if isConversionDataReceived && !conversionData.isEmpty {
            pendingCompletion?(conversionData)
            return
        }
    }
    
    var hasConversionData: Bool {
        return isConversionDataReceived && !conversionData.isEmpty
    }

    var currentConversionData: [String: Any?] {
        return conversionData
    }
    
    // MARK: - Private Methods
}

// MARK: - AppsFlyerLib Delegate Implementation
extension AppsFlyerManager: AppsFlyerLibDelegate {
    func onConversionDataFail(_ error: any Error) {
        DispatchQueue.main.async { [weak self] in
            let nsError = NSError(domain: "AppsFlyer", code: 2001, userInfo: [NSLocalizedDescriptionKey: "AppsFlyer conversion data error: \(error.localizedDescription)"])
            self?.pendingErrorCompletion?(nsError)
            self?.pendingCompletion = nil
            self?.pendingErrorCompletion = nil
        }
    }

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        // Преобразуем [AnyHashable: Any] в [String: Any?]
        var convertedData: [String: Any?] = [:]
        for (key, value) in conversionInfo {
            if let stringKey = key as? String {
                convertedData[stringKey] = value
            } else if let stringKey = key as? NSString {
                convertedData[stringKey as String] = value
            }
        }
        
        self.conversionData = convertedData
        self.isConversionDataReceived = true
        
        DispatchQueue.main.async { [weak self] in
            self?.pendingCompletion?(convertedData)
            self?.pendingCompletion = nil
            self?.pendingErrorCompletion = nil
        }
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {

    }
    
    private func onAppOpenAttributionFailure(_ error: NSError) {

    }
}
