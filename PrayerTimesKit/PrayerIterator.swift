//
//  PrayerIterator.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/26/22.
//

import Foundation
import CoreLocation

struct PrayerIterator: Sequence, IteratorProtocol {
    let calculationParameters: CalculationParameters
    
    private var currentName: Prayer.Name
    private var currentDay: DailyPrayers
    
    init(start: Date, calculationParameters: CalculationParameters) {
        self.calculationParameters = calculationParameters
        
        let daily = DailyPrayers(day: start, calculationParameters: calculationParameters)
        if let active = daily.activePrayer(for: start) {
            currentName = active.name
            currentDay = daily
        } else {
            let yesterday = daily.dhuhr.start.addingTimeInterval(-.day)
            currentName = .isha
            currentDay = DailyPrayers(day: yesterday, calculationParameters: calculationParameters)
        }
    }
    
    mutating func next() -> Prayer? {
        let prayer = currentDay.prayer(named: currentName)
        if currentName == .isha {
            let nextDay = currentDay.dhuhr.start.addingTimeInterval(.day)
            currentDay = DailyPrayers(day: nextDay, calculationParameters: calculationParameters)
        }
        currentName = currentName.next
        return prayer
    }
}

extension Prayer.Name {
    var next: Prayer.Name {
        switch self {
        case .qiyam: return .fajr
        case .fajr: return .sunrise
        case .sunrise: return .dhuhr
        case .dhuhr: return .asr
        case .asr: return .maghrib
        case .maghrib: return .isha
        case .isha: return .qiyam
        }
    }
}
