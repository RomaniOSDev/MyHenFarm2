//
//  AppDelegate.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import UIKit
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Проверка наличия GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("❌ КРИТИЧЕСКАЯ ОШИБКА: GoogleService-Info.plist не найден в bundle!")
            return false
        }
        print("✅ GoogleService-Info.plist найден: \(path)")
        
        // Инициализация Firebase с детальным логированием
        print("🔥 Начинаю инициализацию Firebase...")
        FirebaseApp.configure()
        
        // Проверка успешной инициализации
        if let app = FirebaseApp.app() {
            print("✅ Firebase успешно инициализирован!")
            print("   📦 Project ID: \(app.options.projectID ?? "не указан")")
            print("   📦 Bundle ID: \(app.options.bundleID ?? "не указан")")
            print("   📦 GCM Sender ID: \(app.options.gcmSenderID ?? "не указан")")
        } else {
            print("❌ ОШИБКА: Firebase не инициализирован!")
            return false
        }
        
        // Запрос разрешения на уведомления
        print("📱 Запрашиваю разрешение на уведомления...")
        PushManager.shared.requestAuthorization()
        
        return true
    }

    // МЕТОД - получение APNs токена
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Конвертируем токен в строку для логирования
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("✅ APNs device token получен: \(token)")
        
        // Передаем токен в Firebase Messaging
        print("🔥 Передаю APNs токен в Firebase Messaging...")
        Messaging.messaging().apnsToken = deviceToken
        
        // Проверяем, что токен установлен
        if Messaging.messaging().apnsToken != nil {
            print("✅ APNs токен успешно установлен в Firebase")
        } else {
            print("❌ ОШИБКА: APNs токен не установлен в Firebase")
        }
        
        // Теперь можно запрашивать FCM токен
        print("🔑 Запрашиваю FCM токен...")
        PushManager.shared.retrieveFCMToken()
    }

    // ✅ ДОБАВЬТЕ ЭТОТ МЕТОД - обработка ошибок регистрации
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ КРИТИЧЕСКАЯ ОШИБКА: Не удалось зарегистрироваться для remote notifications")
        print("   Детали: \(error.localizedDescription)")
        print("   Код ошибки: \((error as NSError).code)")
        
        // Проверяем типичные причины ошибок
        let nsError = error as NSError
        if nsError.domain == "com.apple.usernotifications" {
            print("   ⚠️ Проблема с разрешениями на уведомления")
        }
    }
    
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
 

