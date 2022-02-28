//
//  EveryDayTimelineSchedule.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/28/22.
//

import SwiftUI

public struct EveryDayTimelineSchedule: TimelineSchedule {
    public let calendar: Calendar
    
    public struct Entries: Sequence, IteratorProtocol {
        let calendar: Calendar
        var date: Date?
        
        public mutating func next() -> Date? {
            guard let nextDate = date else { return nil }
            
            let dateStart = calendar.startOfDay(for: nextDate)
            date = calendar.date(byAdding: .day, value: 1, to: dateStart)
            
            return dateStart
        }
    }
    
    public func entries(from startDate: Date, mode: Mode) -> Entries {
        Entries(calendar: calendar, date: startDate)
    }
}

extension TimelineSchedule where Self == EveryDayTimelineSchedule {
    public static func everyDay(using calendar: Calendar) -> Self {
        EveryDayTimelineSchedule(calendar: calendar)
    }
}
