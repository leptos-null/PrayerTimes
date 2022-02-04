//
//  Prayer.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation

public struct Prayer: Hashable {
    public enum Name: Hashable, Codable, CaseIterable {
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

public extension Prayer.Name {
    var localized: String {
        switch self {
        case .qiyam:   return NSLocalizedString("PRAYER_NAME_QIYAM",   value: "Qiyam",   comment: "Name for Qiyam prayer")
        case .fajr:    return NSLocalizedString("PRAYER_NAME_FAJR",    value: "Fajr",    comment: "Name for Fajr prayer")
        case .sunrise: return NSLocalizedString("PRAYER_NAME_SUNRISE", value: "Sunrise", comment: "Name for sunrise")
        case .dhuhr:   return NSLocalizedString("PRAYER_NAME_DHUHR",   value: "Dhuhr",   comment: "Name for Dhuhr prayer")
        case .asr:     return NSLocalizedString("PRAYER_NAME_ASR",     value: "Asr",     comment: "Name for Asr prayer")
        case .maghrib: return NSLocalizedString("PRAYER_NAME_MAGHRIB", value: "Maghrib", comment: "Name for Maghrib prayer")
        case .isha:    return NSLocalizedString("PRAYER_NAME_ISHA",    value: "Isha",    comment: "Name for Isha prayer")
        }
    }
}
