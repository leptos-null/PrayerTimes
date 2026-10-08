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
            let windowBarHeight: CGFloat = if #available(macCatalyst 26.0, *) {
                52
            } else {
                28
            }
            return WindowGroup {
                ContentView()
            }
            // size per
            // <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>
            .defaultSize(width: 1280, height: 800 - windowBarHeight)
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
