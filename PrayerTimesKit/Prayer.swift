//
//  Prayer.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation

struct Prayer: Hashable {
    enum Name: Hashable {
        case qiyam
        case fajr
        case dhuhr
        case asr
        case maghrib
        case isha
    }
    
    let name: Name
    let start: Date
    let end: Date
    
    var dateInterval: DateInterval {
        DateInterval(start: start, end: end)
    }
    
    init(_ name: Name, start: Date, end: Date) {
        self.name = name
        self.start = start
        self.end = end
    }
}
