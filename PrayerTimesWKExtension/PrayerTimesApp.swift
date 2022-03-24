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
    
    init() {
        systemRegistrar.startRegistering()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
