//
//  AppDelegate.swift
//  PrayerTimes
//
//  Created by Leptos on 1/18/22.
//

import UIKit
import PrayerTimesKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let systemRegistrar = SystemRegistrar()
    let widgetManager = WidgetManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserNotification.Manager.current.configure()
#if !SCREENSHOT_MODE
        systemRegistrar.startRegistering()
        widgetManager.startMonitoring()
#endif
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        //   this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}
