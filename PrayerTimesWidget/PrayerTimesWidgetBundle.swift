//
//  PrayerTimesWidgetBundle.swift
//  PrayerTimesWidget
//
//  Created by Leptos on 7/8/24.
//

import WidgetKit
import SwiftUI
import PrayerTimesKit

@main
struct PrayerTimesWidgetBundle: WidgetBundle {
    let widgetManager = WidgetManager()
    
    init() {
        widgetManager.startMonitoring()
    }
    
    var body: some Widget {
        UpNextWidget()
    }
}
