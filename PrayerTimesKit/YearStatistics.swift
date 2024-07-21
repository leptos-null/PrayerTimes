//
//  YearStatistics.swift
//  PrayerTimesKit
//
//  Created by Leptos on 7/20/24.
//

import Foundation

public struct YearStatistics {
    public let era: Int
    public let year: Int
    public let calendar: Calendar
    public let calculationParameters: CalculationParameters
    
    public let dateInterval: DateInterval
    
    public let daysPrayers: [DailyPrayers]
    
    public init(date: Date, calendar: Calendar, calculationParameters: CalculationParameters) {
        let era = calendar.component(.era, from: date)
        let year = calendar.component(.year, from: date)
        self.init(era: era, year: year, calendar: calendar, calculationParameters: calculationParameters)
    }
    
    public init(era: Int, year: Int, calendar: Calendar, calculationParameters: CalculationParameters) {
        self.era = era
        self.year = year
        self.calendar = calendar
        self.calculationParameters = calculationParameters
        
        let date = calendar.date(from: .init(era: era, year: year))!
        dateInterval = calendar.dateInterval(of: .year, for: date)!
        
        daysPrayers = (0...)
            .lazy
            .compactMap { day in
                let dateComponents = DateComponents(year: year, day: day)
                return calendar.date(from: dateComponents)
            }
            .drop { calendar.component(.year, from: $0) != year }
            .prefix { calendar.component(.year, from: $0) == year }
            .map { date in
                DailyPrayers(day: date, calculationParameters: calculationParameters)
            }
    }
}

public extension YearStatistics {
    func longestDay(from startName: Prayer.Name = .fajr, to endName: Prayer.Name = .maghrib) -> DailyPrayers {
        let longest = daysPrayers.max { lhs, rhs in
            lhs.timeInterval(from: startName, to: endName) < rhs.timeInterval(from: startName, to: endName)
        }
        return longest!
    }
}

public extension DailyPrayers {
    func timeInterval(from startName: Prayer.Name, to endName: Prayer.Name) -> TimeInterval {
        let endPrayer = prayer(named: endName)
        let startPrayer = prayer(named: startName)
        return endPrayer.start.timeIntervalSince(startPrayer.start)
    }
}
