//
//  Prayer.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation

public struct Prayer: Hashable {
    public enum Name: Hashable, CaseIterable {
        case qiyam
        case fajr
        case sunrise
        case dhuhr
        case asr
        case maghrib
        case isha
    }
    
    public let name: Name
    public let start: Date
    
    init(_ name: Name, start: Date) {
        self.name = name
        self.start = start
    }
}
