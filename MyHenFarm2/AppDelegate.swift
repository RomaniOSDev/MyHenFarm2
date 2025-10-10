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

 let pushManager = PushManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
           print("✅ Firebase configured IMMEDIATELY")
           
           // Проверка
           if let app = FirebaseApp.app() {
               print("🔥 Firebase app name: \(app.name)")
           }
        pushManager.requestAuthorization()
        
        UNUserNotificationCenter.current().delegate = pushManager
        
        Messaging.messaging().delegate = pushManager
        
        //Help debug fuctions
        checkFCMToken()
        requestNotificationPermission()
        checkNotificationStatusImmediately()
        
        return true
    }
    
    //MARK: - Helpers
    private func checkNotificationStatusImmediately() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("🔔 Initial notification status: \(settings.authorizationStatus.rawValue)")
                
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    print("🚀 Status is authorized - calling registerForRemoteNotifications()")
                    UIApplication.shared.registerForRemoteNotifications()
                    
                case .notDetermined:
                    print("🤔 Status not determined - will request later")
                    // Будет запрошено в NotificationPermissionView
                    
                case .denied:
                    print("❌ Status denied by user")
                    
                @unknown default:
                    print("❓ Unknown status")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("🆕 Requesting notification permission...")
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        if granted {
                            print("✅ Permission granted - waiting for APNS token...")
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                    
                case .authorized, .provisional:
                    print("✅ Already authorized - registering for APNS...")
                    UIApplication.shared.registerForRemoteNotifications()
                    
                case .denied:
                    print("❌ Notifications denied")
                    
                @unknown default: break
                }
            }
        }
    }
    private func checkFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM token error: \(error.localizedDescription)")
            } else if let token = token {
                print("🔥 FCM TOKEN SUCCESS: \(token)")
                UserDefaults.standard.set(token, forKey: "fcmToken")
                
                // Проверка сохранения
                if let savedToken = UserDefaults.standard.string(forKey: "fcmToken") {
                    print("💾 FCM token saved: \(savedToken)")
                }
            }
        }
    }

    // Вызовите после requestAuthorization()
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNS token received")
           Messaging.messaging().apnsToken = deviceToken
           
           // Конвертация для логов
           let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
           print("📱 APNS Token: \(tokenString)")
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ FAILED to register for remote notifications: \(error.localizedDescription)")
           
           // 🔥 ЭТО КРИТИЧЕСКИ ВАЖНО - покажет причину
           let nsError = error as NSError
           print("🔧 Error details: \(nsError.domain), code: \(nsError.code)")
           print("🔧 UserInfo: \(nsError.userInfo)")
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

