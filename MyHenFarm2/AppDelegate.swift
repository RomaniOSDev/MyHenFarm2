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
        FirebaseApp.configure()
        PushManager.shared.requestAuthorization()
        return true
    }

    // ✅ ДОБАВЬТЕ ЭТОТ МЕТОД - получение APNs токена
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            print("📱 APNs device token received")
            // Передаем токен в Firebase Messaging
            Messaging.messaging().apnsToken = deviceToken
            
            // Теперь можно запрашивать FCM токен
            PushManager.shared.retrieveFCMToken()
        }

        // ✅ ДОБАВЬТЕ ЭТОТ МЕТОД - обработка ошибок регистрации
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("❌ Failed to register for remote notifications: \(error)")
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
 

