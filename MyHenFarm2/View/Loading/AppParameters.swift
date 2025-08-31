//
//  AppParameters.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//

import Foundation

// MARK: - Network Configuration
struct NetworkConfiguration {
    var baseURL: String
    let timeoutInterval: TimeInterval
    let retryCount: Int
    let retryDelay: TimeInterval
    
    static let `default` = NetworkConfiguration(
        baseURL: "https://henhousefarm.com/config.php",
        timeoutInterval: 30.0,
        retryCount: 3,
        retryDelay: 2.0
    )
}

// MARK: - App Parameters Configuration
struct AppParameters {
    
    // MARK: - AppsFlyer Configuration
    static let appsFlyerDevKey = "MpXBqoJbLGfY86Guq7dNK9"
    static let appsFlyerAppID = "6751569488"
    
    // MARK: - Required Parameters for Config Endpoint
    static let requiredParameters: [String: Any] = [
        "bundle_id": Bundle.main.bundleIdentifier ?? "com.henhousefarm234.rre3",
        "os": "iOS",
        "store_id": "id6751569488",
        "locale": Locale.current.identifier
    ]
    
    // MARK: - Network Configuration
    static let networkConfiguration = NetworkConfiguration(
        baseURL: "https://henhousefarm.com/config.php",
        timeoutInterval: 30.0,
        retryCount: 3,
        retryDelay: 2.0
    )
}

// MARK: - AppsFlyer Parameter Extensions
extension AppParameters {
    
    /// Получить af_id (AppsFlyer ID) из AppsFlyer SDK
    /// - Returns: AppsFlyer ID или nil если недоступен
    static func getAppsFlyerID() -> String? {
        // Здесь будет вызов AppsFlyer SDK для получения ID
        // AppsFlyerLib.shared().getAppsFlyerUID() или AppsFlyerLib.shared().getAppsFlyerId()
        return nil // Пока возвращаем nil, будет реализовано позже
    }
    
    /// Получить push_token из Firebase
    /// - Returns: Push token или nil если недоступен
    static func getPushToken() -> String? {
        // Здесь будет получение push token из Firebase
        // Messaging.messaging().fcmToken
        return nil // Пока возвращаем nil, будет реализовано позже
    }
    
    /// Получить firebase_project_id
    /// - Returns: Firebase Project ID или nil если недоступен
    static func getFirebaseProjectID() -> String? {
        // Здесь будет получение Firebase Project ID
        // FirebaseApp.app()?.options.projectID
        return nil // Пока возвращаем nil, будет реализовано позже
    }
}

