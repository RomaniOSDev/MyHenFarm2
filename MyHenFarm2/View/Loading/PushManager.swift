//
//  PushManager.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 09.10.2025.
//

import FirebaseMessaging
import UserNotifications
import UIKit

class PushManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {

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
        }
    }

    // Получение токена FCM
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 FCM Token: \(fcmToken ?? "")")
        // Можно отправить токен на сервер
    }

    // Обработка уведомлений, если нужно
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📩 Notification tapped: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}
