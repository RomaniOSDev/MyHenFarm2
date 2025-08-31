//
//  SceneDelegate.swift
//  MyHenFarm2
//
//  Created by Роман Главацкий on 21.08.2025.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        
        let controller: UIViewController
        
        if let lastUrl = SaveService.lastUrl, let savedTime = SaveService.time {
            if let expirationDate = parseDate(from: savedTime), Date() < expirationDate {
                controller = WebviewVC(url: lastUrl)
            } else {
                SaveService.lastUrl = nil
                SaveService.time = nil
                controller = LoadingView()
            }
        } else {
            controller = LoadingView()
        }
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func parseDate(from dateString: String) -> Date? {
        let dateFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.timeZone = TimeZone.current
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone.current
                return formatter
            }()
        ]
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        if let timestamp = Double(dateString) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
}

