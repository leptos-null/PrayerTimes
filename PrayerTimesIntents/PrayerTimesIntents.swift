//
//  PrayerTimesIntents.swift
//  PrayerTimesIntents
//
//  Created by Leptos on 6/16/24.
//

import AppIntents

struct PrayerTimesIntents: AppIntent {
    static var title: LocalizedStringResource = "PrayerTimesIntents"
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
