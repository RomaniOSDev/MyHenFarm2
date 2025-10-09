//
//  PushManager.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 09.10.2025.
//

import FirebaseMessaging
import UserNotifications
import UIKit

final class PushManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            print(granted ? "✅ Push permission granted" : "❌ Push permission denied")
        }
    }

    // Получение токена FCM
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 FCM Token: \(fcmToken ?? "")")
    }

    // Нажатие на пуш
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 Notification tapped: \(userInfo)")

        // Извлекаем URL из data
        if let data = userInfo["data"] as? [String: Any],
           let urlString = data["url"] as? String,
           let url = URL(string: urlString),
           !urlString.isEmpty {

            NotificationCenter.default.post(
                name: .pushOpenedWithURL,
                object: nil,
                userInfo: ["url": url]
            )
        }

        completionHandler()
    }

    // Отображение уведомления, если приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

extension Notification.Name {
    static let pushOpenedWithURL = Notification.Name("pushOpenedWithURL")
}
