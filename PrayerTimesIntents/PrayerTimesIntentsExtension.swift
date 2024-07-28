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
                // A phrase _must_ have `.applicationName` to be recognized.
                //
                // See the following WWDC video for more information
                //   on phrase requirements and abilities:
                // https://developer.apple.com/wwdc22/10170?time=903
                //   > Parameters are not meant for open-ended values.
                //   > For example, it's not possible to gather an arbitrary string
                //   > from the user in the initial utterance.
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
