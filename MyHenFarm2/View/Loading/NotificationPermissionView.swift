//
//  NotificationPermissionView.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    
    // MARK: - Properties
    let webURL: URL
    let appsFlyerData: [String: Any?]
    let additionalData: [String: Any]
    let networkManager: NetworkManager
    let orientation = UIDevice.current.orientation
    @State private var isAgreed = false
    @State private var backgroundImageName: ImageResource = .notif1
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isLoading = false
    @State private var fcmToken: String?
    @Environment(\.dismiss) private var dismiss
    private let skipKey = "NotificationSkipDate"
    @State private var fcmTokenTimeout: DispatchWorkItem?
    
    // MARK: - Initialization
    init(webURL: URL, appsFlyerData: [String: Any?], additionalData: [String: Any], networkManager: NetworkManager) {
        self.webURL = webURL
        self.appsFlyerData = appsFlyerData
        self.additionalData = additionalData
        self.networkManager = networkManager
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Fullscreen background without side gaps
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .clipped()
                
            
            // Content - показываем только если разрешение не определено
            if notificationStatus == .notDetermined {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Icon
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.top, 60)
                    
                    // Title
                    Text("Allow notifications aboutbonuses and promos")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                        .padding(.horizontal, 40)
                    
                    // Message
                    Text("Stay tuned with best offers from our casino")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        // Agree button
                        Button(action: {
                            print("✅ User agreed to notifications")
                            isAgreed = true
                            proceedWithNativePermissionRequest()
                        }) {
                            Text("Yes, I Want Bonuses!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        // Skip button
                        Button(action: {
                            print("⏭️ User skipped notifications")
                            isAgreed = false
                            UserDefaults.standard.set(Date(), forKey: skipKey)
                            openWebView()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                // Показываем загрузку если разрешение уже определено
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    Spacer()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateBackgroundForOrientation()
        }
        .onAppear {
            updateBackgroundForOrientation()
            handleInitialPermissionFlow()
            setupNotificationObservers()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: - Private Methods
    private func handleInitialPermissionFlow() {
        if let lastSkip = UserDefaults.standard.object(forKey: skipKey) as? Date {
            let threeDays: TimeInterval = 3 * 24 * 60 * 60
            if Date().timeIntervalSince(lastSkip) < threeDays {
                print("⏭️ Recently skipped (<3 days). Skipping permission screen.")
                openWebView()
                return
            }
        }
        checkNotificationPermissionStatus()
    }
    
    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
                print("🔔 Notification status: \(self.notificationStatus.rawValue)")
                
                // Если разрешение уже получено или отклонено, сразу открываем WebView
                if settings.authorizationStatus != .notDetermined {
                    print("📱 Notification permission already determined, opening WebView directly")
                    self.openWebView()
                } else {
                    print("📱 Showing custom notification permission screen")
                    // Показываем кастомный экран, пользователь должен нажать кнопку
                }
            }
        }
    }
    
    private func updateBackgroundForOrientation() {
        let orientation = UIDevice.current.orientation
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if orientation.isLandscape {
                // Горизонтальная ориентация
                backgroundImageName = .notif2
            } else {
                // Вертикальная ориентация
                backgroundImageName = .notif1
            }
        }
    }
    
    private func requestNotificationPermission() {
        // Сначала показываем кастомный экран разрешений
        // Пользователь должен нажать "Yes, I Want Bonuses!" чтобы продолжить
        print("📱 Showing custom notification permission screen")
    }
    
    private func proceedWithNativePermissionRequest() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                    // При ошибке сразу открываем WebView
                    openWebView()
                } else if granted {
                    print("✅ Notification permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    // Ждем FCM токен с таймаутом
                    isLoading = true
                    startFCMTokenTimeout()
                } else {
                    print("❌ Notification permission denied")
                    // При отказе сразу открываем WebView
                    openWebView()
                }
            }
        }
    }
    
    private func openWebView() {
        print("🌐 Opening WebView with URL: \(webURL)")
        
        DispatchQueue.main.async {
            // Находим текущий view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                print("✅ Found root view controller: \(type(of: rootViewController))")
                
                // Если есть модальный view controller, закрываем его сначала
                if let presentedVC = rootViewController.presentedViewController {
                    print("📱 Dismissing current modal: \(type(of: presentedVC))")
                    presentedVC.dismiss(animated: true) {
                        print("✅ Modal dismissed, presenting WebView")
                        self.presentWebView(from: rootViewController)
                    }
                } else {
                    print("📱 No modal to dismiss, presenting WebView directly")
                    self.presentWebView(from: rootViewController)
                }
            } else {
                print("❌ Could not find root view controller")
            }
        }
    }
    
    private func presentWebView(from viewController: UIViewController) {
        print("🚀 Creating WebView with URL: \(webURL)")
        let webviewVC = WebviewVC(url: webURL)
        //let webviewVC = SafariTabsVC(url: webURL)
        webviewVC.modalPresentationStyle = .fullScreen
        
        print("📱 Presenting WebView from: \(type(of: viewController))")
        viewController.present(webviewVC, animated: true) {
            print("✅ WebView presented successfully")
        }
    }
    
    // MARK: - FCM Token Handling
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .fcmTokenReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let token = notification.userInfo?["token"] as? String {
                print("🔑 FCM Token received in NotificationPermissionView: \(token)")
                
                // Отменяем таймаут
                fcmTokenTimeout?.cancel()
                fcmTokenTimeout = nil
                
                // Показываем алерт с номером токена
                showFCMTokenReceivedAlert(token: token)
            }
        }
    }
    
    private func sendSecondNetworkRequestWithToken(_ token: String) {
        print("🔄 Sending second network request with FCM token...")
        
        // Добавляем FCM токен к данным
        var updatedAppsFlyerData = appsFlyerData
        updatedAppsFlyerData["fcm_token"] = token
        
        networkManager.sendConversionData(
            appsFlyerData: updatedAppsFlyerData,
            additionalData: additionalData
        ) { result in
            DispatchQueue.main.async {
                self.handleSecondNetworkResult(result)
            }
        }
    }
    
    
    private func handleSecondNetworkResult(_ result: Result<Data, NSError>) {
        switch result {
        case .success(let data):
            handleSecondSuccessResponse(data)
        case .failure(let error):
            print("❌ Second network request failed: \(error.localizedDescription)")
            // При ошибке открываем WebView с оригинальным URL
            openWebView()
        }
    }
    
    private func handleSecondSuccessResponse(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("❌ Invalid JSON in second response")
                openWebView()
                return
            }
            
            guard let status = json["ok"] as? Bool, status == true else {
                let message = json["message"] as? String ?? "Server error"
                print("❌ Server error in second response: \(message)")
                openWebView()
                return
            }

            if let finalUrlString = json["url"] as? String, !finalUrlString.isEmpty {
                print("✅ Second response success! Final URL: \(finalUrlString)")
                if let finalURL = URL(string: finalUrlString) {
                    // Обновляем URL и открываем WebView
                    openWebViewWithURL(finalURL)
                } else {
                    openWebView()
                }
            } else {
                print("❌ No URL in second response")
                openWebView()
            }
            
        } catch {
            print("❌ JSON parsing error in second response: \(error.localizedDescription)")
            openWebView()
        }
    }
    
    private func openWebViewWithURL(_ url: URL) {
        print("🌐 Opening WebView with final URL: \(url.absoluteString)")
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let presentedVC = rootViewController.presentedViewController {
                    presentedVC.dismiss(animated: true) {
                        self.presentWebView(from: rootViewController, url: url)
                    }
                } else {
                    self.presentWebView(from: rootViewController, url: url)
                }
            }
        }
    }
    
    private func presentWebView(from viewController: UIViewController, url: URL) {
        let webviewVC = WebviewVC(url: url)
        webviewVC.modalPresentationStyle = .fullScreen
        viewController.present(webviewVC, animated: true)
    }
    
    // MARK: - FCM Token Timeout
    private func startFCMTokenTimeout() {
        fcmTokenTimeout?.cancel()
        fcmTokenTimeout = DispatchWorkItem {
            DispatchQueue.main.async {
                print("⏰ FCM token timeout in NotificationPermissionView")
                self.showFCMTokenTimeoutAlert()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: fcmTokenTimeout!)
    }
    
    private func showFCMTokenTimeoutAlert() {
        let alert = UIAlertController(
            title: "Уведомления недоступны",
            message: "Не удалось получить токен для push-уведомлений. Приложение будет работать без уведомлений.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { _ in
            self.openWebView()
        })
        
        // Находим текущий view controller для показа алерта
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func showFCMTokenReceivedAlert(token: String) {
        let alert = UIAlertController(
            title: "FCM Токен получен",
            message: "Токен: \(token)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отправить запрос", style: .default) { _ in
            self.sendSecondNetworkRequestWithToken(token)
        })
        
        // Находим текущий view controller для показа алерта
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationPermissionView(
        webURL: URL(string: "https://google.com")!,
        appsFlyerData: [:],
        additionalData: [:],
        networkManager: NetworkManager()
    )
}
