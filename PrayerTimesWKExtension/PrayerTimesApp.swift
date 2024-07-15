//
//  PrayerTimesApp.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/18/22.
//

import SwiftUI
import PrayerTimesKit

@main
struct PrayerTimesApp: App {
    let systemRegistrar = SystemRegistrar()
    let widgetManager = WidgetManager()
    
    init() {
        systemRegistrar.startRegistering()
        if #available(watchOS 9.0, *) {
            widgetManager.startMonitoring()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
