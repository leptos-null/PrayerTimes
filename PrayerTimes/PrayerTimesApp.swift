//
//  PrayerTimesApp.swift
//  PrayerTimes
//
//  Created by Leptos on 6/25/24.
//

import SwiftUI

@main
struct PrayerTimesApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
#if SCREENSHOT_MODE && targetEnvironment(macCatalyst)
        if #available(macCatalyst 17.0, *) {
            return WindowGroup {
                ContentView()
            }
            .defaultSize(width: 1280, height: 800 - 28) // menu bar height
        } else {
            fatalError("defaultSize requires macCatalyst 17.0")
        }
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}
