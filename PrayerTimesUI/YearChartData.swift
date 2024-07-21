//
//  YearChartData.swift
//  PrayerTimesUI
//
//  Created by Leptos on 7/21/24.
//

import Foundation
import PrayerTimesKit

public struct YearChartData {
    public struct Point: Hashable, Identifiable {
        public let date: Date
        public let offset: TimeInterval
        
        public var id: Self { self }
    }
    
    public let statistics: YearStatistics
    public let seriesMap: [Prayer.Name: [Point]]
    
    public init(statistics: YearStatistics, visiblePrayers: Set<Prayer.Name>) {
        self.statistics = statistics
        self.seriesMap = statistics.daysPrayers.reduce(into: [:]) { partialResult, dailyPrayers in
            let startOfDay = statistics.calendar.startOfDay(for: dailyPrayers.dhuhr.start)
            for prayer in visiblePrayers {
                let prayerStart = dailyPrayers.prayer(named: prayer).start
                let offset = prayerStart.timeIntervalSince(startOfDay)
                partialResult[prayer, default: []].append(.init(date: prayerStart, offset: offset))
            }
        }
    }
}
