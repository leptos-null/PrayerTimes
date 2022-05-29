//
//  VisiblePrayersEnvironmentKey.swift
//  PrayerTimesUI
//
//  Created by Leptos on 5/29/22.
//

import SwiftUI
import PrayerTimesKit

private struct VisiblePrayersEnvironmentKey: EnvironmentKey {
    static let defaultValue: Set<Prayer.Name> = Set(Prayer.Name.allCases)
}

public extension EnvironmentValues {
    var visiblePrayers: Set<Prayer.Name> {
        get { self[VisiblePrayersEnvironmentKey.self] }
        set { self[VisiblePrayersEnvironmentKey.self] = newValue }
    }
}
