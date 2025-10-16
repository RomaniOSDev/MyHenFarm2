import FirebaseMessaging
import UserNotifications
import UIKit

class PushManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    static let shared = PushManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("📱 Notification permission granted: \(granted), error: \(error?.localizedDescription ?? "none")")
            
            DispatchQueue.main.async {
                if granted {
                    // Регистрируем для remote notifications
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ User denied notification permissions")
                }
            }
        }
    }

    // ✅ ДОБАВЬТЕ ЭТОТ МЕТОД - запрос FCM токена после получения APNs
    func retrieveFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error)")
            } else if let token = token {
                print("✅ FCM registration token: \(token)")
                // Здесь можно отправить токен на ваш сервер
            }
        }
    }

    // ✅ Получение FCM токена (вызывается автоматически Firebase)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 FCM Token received: \(fcmToken ?? "no token")")
    }

    // ✅ Обработка уведомлений при тапе
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 Notification tapped: \(userInfo)")
        completionHandler()
    }
    
    // ✅ Обработка уведомлений когда приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📩 Notification received while app is active: \(userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
}
