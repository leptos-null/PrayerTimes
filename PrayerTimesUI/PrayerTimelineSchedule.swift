//
//  PrayerTimelineSchedule.swift
//  PrayerTimesUI
//
//  Created by Leptos on 3/19/22.
//

import SwiftUI
import PrayerTimesKit

public struct PrayerTimelineSchedule: TimelineSchedule {
    public let calculationParameters: CalculationParameters
    public let visiblePrayers: Set<Prayer.Name>
    
    public func entries(from startDate: Date, mode: Mode) -> LazyMapSequence<PrayerIterator, Date> {
        PrayerIterator(start: startDate, calculationParameters: calculationParameters, filter: visiblePrayers)
            .lazy
            .map(\.start)
    }
}

extension TimelineSchedule where Self == PrayerTimelineSchedule {
    public static func prayers(with calculationParameters: CalculationParameters, visiblePrayers: Set<Prayer.Name>) -> Self {
        PrayerTimelineSchedule(calculationParameters: calculationParameters, visiblePrayers: visiblePrayers)
    }
}
