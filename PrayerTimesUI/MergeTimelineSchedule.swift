//
//  MergeTimelineSchedule.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/28/22.
//

import SwiftUI

public struct MergeTimelineSchedule<TimelineSchedule1: TimelineSchedule, TimelineSchedule2: TimelineSchedule>: TimelineSchedule {
    let timelineSchedule1: TimelineSchedule1
    let timelineSchedule2: TimelineSchedule2
    
    public struct Entries: Sequence, IteratorProtocol {
        var entries1: TimelineSchedule1.Entries.Iterator
        var entries2: TimelineSchedule2.Entries.Iterator
        
        public mutating func next() -> Date? {
            var entriesCopy1 = entries1
            var entriesCopy2 = entries2
            
            let propose1 = entriesCopy1.next()
            let propose2 = entriesCopy2.next()
            
            if let propose1 = propose1, let propose2 = propose2 {
                if propose1 == propose2 {
                    entries1 = entriesCopy1
                    entries2 = entriesCopy2
                    return propose1
                } else if propose1 < propose2 {
                    entries1 = entriesCopy1
                    return propose1
                } else {
                    entries2 = entriesCopy2
                    return propose2
                }
            } else if propose1 != nil {
                entries1 = entriesCopy1
                return propose1
            } else if propose2 != nil {
                entries2 = entriesCopy2
                return propose2
            } else {
                return nil
            }
        }
    }
    
    public func entries(from startDate: Date, mode: Mode) -> Entries {
        Entries(
            entries1: timelineSchedule1.entries(from: startDate, mode: mode).makeIterator(),
            entries2: timelineSchedule2.entries(from: startDate, mode: mode).makeIterator()
        )
    }
}

extension MergeTimelineSchedule {
    public static func merge(_ ts1: TimelineSchedule1, _ ts2: TimelineSchedule2) -> Self {
        MergeTimelineSchedule(timelineSchedule1: ts1, timelineSchedule2: ts2)
    }
}
