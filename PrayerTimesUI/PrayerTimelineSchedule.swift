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
    
    public func entries(from startDate: Date, mode: Mode) -> LazyMapSequence<PrayerIterator, Date> {
        PrayerIterator(start: startDate, calculationParameters: calculationParameters)
            .lazy
            .map(\.start)
    }
}

extension TimelineSchedule where Self == PrayerTimelineSchedule {
    public static func prayers(with calculationParameters: CalculationParameters) -> Self {
        PrayerTimelineSchedule(calculationParameters: calculationParameters)
    }
}
