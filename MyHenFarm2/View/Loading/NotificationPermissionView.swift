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
    let orientation = UIDevice.current.orientation
    @State private var isAgreed = false
    @State private var backgroundImageName: ImageResource = .notif1
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    init(webURL: URL) {
        self.webURL = webURL
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background image
            
            if orientation.isPortrait {
                Image(backgroundImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            }else{
                Image(backgroundImageName)
                    .resizable()
                    .ignoresSafeArea()
            }
                
            
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
                            requestNotificationPermission()
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
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateBackgroundForOrientation()
        }
        .onAppear {
            updateBackgroundForOrientation()
            checkNotificationPermissionStatus()
        }
    }
    
    // MARK: - Private Methods
    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
                print("🔔 Notification status: \(self.notificationStatus.rawValue)")
                
                // Если разрешение уже получено или отклонено, сразу открываем WebView
                if settings.authorizationStatus != .notDetermined {
                    print("📱 Notification permission already determined, opening WebView directly")
                    self.openWebView()
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied")
                }
                
                // Открываем WebView в любом случае
                openWebView()
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
        webviewVC.modalPresentationStyle = .fullScreen
        
        print("📱 Presenting WebView from: \(type(of: viewController))")
        viewController.present(webviewVC, animated: true) {
            print("✅ WebView presented successfully")
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationPermissionView(webURL: URL(string: "https://google.com")!)
}
