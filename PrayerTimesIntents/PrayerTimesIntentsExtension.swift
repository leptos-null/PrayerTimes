//
//  PrayerTimesIntentsExtension.swift
//  PrayerTimesIntents
//
//  Created by Leptos on 6/16/24.
//

import AppIntents

@main
struct PrayerTimesIntentsExtension: AppIntentsExtension {
}

struct PrayerTimesShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PrayerTimeIntent(),
            phrases: [
                // a phrase _must_ have `.applicationName` to be recognized.
                //
                // my understanding is that each phrase essentially must be able
                // to be statically matched. in other words, variables that
                // cannot be enumerated quickly cannot be recognized.
                // for example, CLPlacemark cannot be part of the phrase because
                // all of the strings to represent all of the placemarks cannot
                // be reasonably enumerated.
                // in my testing, Int and Date also are not matchable.
                "According to \(.applicationName), what time is \(\.$targetPrayer)?",
                "According to \(.applicationName), when is \(\.$targetPrayer)?",
                "According to \(.applicationName), what time is \(\.$targetPrayer) today?",
                "According to \(.applicationName), when is \(\.$targetPrayer) today?",
            ],
            shortTitle: "Prayer Time",
            systemImageName: "clock"
        )
    }
}
