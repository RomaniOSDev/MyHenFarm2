//
//  AppParameters.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//

import Foundation
import AppsFlyerLib
import FirebaseMessaging
import FirebaseCore

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
    /// Динамически формирует параметры для запроса, включая push_token и firebase_project_id
    static var requiredParameters: [String: Any] {
        var parameters: [String: Any] = [
            "bundle_id": Bundle.main.bundleIdentifier ?? "com.henhousefarm234.rre3",
            "os": "iOS",
            "store_id": "id6751569488",
            "locale": Locale.current.identifier
        ]
        
        // Добавляем push_token, если доступен
        if let pushToken = getPushToken() {
            parameters["push_token"] = pushToken
        }
        
        // Добавляем firebase_project_id, если доступен
        if let projectID = getFirebaseProjectID() {
            parameters["firebase_project_id"] = projectID
        }
        
        return parameters
    }
    
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
    static func getAppsFlyerID() -> String? {
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }
    
    /// Получить push_token из Firebase
    static func getPushToken() -> String? {
        print("🔑 getPushToken() вызван")
        
        let token = Messaging.messaging().fcmToken
        
        if let token = token {
            print("✅ FCM токен получен через getPushToken(): \(token)")
            return token
        } else {
            print("⚠️ FCM токен еще не доступен (nil)")
            print("   Возможные причины:")
            print("   - Firebase еще не получил токен")
            print("   - APNs токен еще не был установлен")
            print("   - Разрешение на уведомления не получено")
            return nil
        }
    }
    
    /// Получить firebase_project_id
    /// - Returns: Firebase Project ID или nil если недоступен
    static func getFirebaseProjectID() -> String? {
        guard let app = FirebaseApp.app(),
              let projectID = app.options.projectID else {
            print("⚠️ Firebase Project ID недоступен")
            return nil
        }
        print("✅ Firebase Project ID получен: \(projectID)")
        return projectID
    }
}

