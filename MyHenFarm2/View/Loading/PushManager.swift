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
        print("🔔 Запрашиваю разрешение на уведомления...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Ошибка при запросе разрешения: \(error.localizedDescription)")
                return
            }
            
            print("📱 Результат запроса разрешения: \(granted ? "✅ Разрешено" : "❌ Отклонено")")
            
            DispatchQueue.main.async {
                if granted {
                    print("📲 Регистрирую приложение для remote notifications...")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ Пользователь отклонил разрешение на уведомления")
                }
            }
        }
    }

    // ✅ ДОБАВЬТЕ ЭТОТ МЕТОД - запрос FCM токена после получения APNs
    func retrieveFCMToken() {
        print("🔑 Запрашиваю FCM токен через token()...")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ ОШИБКА при получении FCM токена: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   Код ошибки: \(nsError.code)")
                    print("   Домен: \(nsError.domain)")
                    print("   UserInfo: \(nsError.userInfo)")
                }
            } else if let token = token {
                print("✅ FCM registration token получен через token(): \(token)")
                // Здесь можно отправить токен на ваш сервер
            } else {
                print("⚠️ FCM токен не получен (token = nil)")
            }
        }
    }

    // ✅ Получение FCM токена (вызывается автоматически Firebase)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("🔑 FCM Token получен через делегат didReceiveRegistrationToken: \(token)")
            print("   ✅ Регистрация в Firebase успешна!")
        } else {
            print("⚠️ FCM Token = nil в делегате")
        }
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
