//
//  PrayerIterator.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/26/22.
//

import Foundation
import CoreLocation

public struct PrayerIterator: Sequence, IteratorProtocol {
    public let calculationParameters: CalculationParameters
    
    private let sortedNames: [Prayer.Name]
    
    private var currentNameIndex: Int
    private var currentDay: DailyPrayers
    
    public init(start: Date, calculationParameters: CalculationParameters, filter: Set<Prayer.Name> = Set(Prayer.Name.allCases)) {
        let sortedNames = filter.sorted()
        
        self.calculationParameters = calculationParameters
        self.sortedNames = sortedNames
        
        let daily = DailyPrayers(day: start, calculationParameters: calculationParameters)
        if let active = daily.ordered.filter(filter).activePrayer(for: start) {
            currentNameIndex = sortedNames.firstIndex(of: active.name) ?? -1
            currentDay = daily
        } else {
            let yesterday = daily.dhuhr.start.addingTimeInterval(-.day)
            currentNameIndex = sortedNames.indices.last ?? -1
            currentDay = DailyPrayers(day: yesterday, calculationParameters: calculationParameters)
        }
    }
    
    public mutating func next() -> Prayer? {
        guard !sortedNames.isEmpty else { return nil }
        
        let prayer = currentDay.prayer(named: sortedNames[currentNameIndex])
        if currentNameIndex != sortedNames.indices.last {
            currentNameIndex = sortedNames.index(after: currentNameIndex)
        } else {
            let nextDay = currentDay.dhuhr.start.addingTimeInterval(.day)
            currentDay = DailyPrayers(day: nextDay, calculationParameters: calculationParameters)
            currentNameIndex = sortedNames.indices.first ?? -1
        }
        return prayer
    }
}
