//
//  YearStatistics.swift
//  PrayerTimesKit
//
//  Created by Leptos on 7/20/24.
//

import Foundation

public struct YearStatistics {
    public let calendar: Calendar
    public let calculationParameters: CalculationParameters
    
    public let dateInterval: DateInterval
    
    public let daysPrayers: [DailyPrayers]
    
    public init(date: Date, calendar: Calendar, calculationParameters: CalculationParameters) {
        self.calendar = calendar
        self.calculationParameters = calculationParameters
        
        // A year may span 2 eras. For example, in the Japanese calendar:
        //   - 4/1/H31 (era: 235, year: 31, month: 4, day: 1)
        //   - 5/1/R1  (era: 236, year: 1, month: 5, day: 1)
        // in this case, (era: 236, year: 1, month: 4) does not exist in the calendar;
        // making a query with those components resolves to (era: 235, year: 31, month: 4).
        //
        // For this reason, to find each day in a year, the code below adds a day
        // to the start of the year until the date is no longer in the year.
        
        let dateInterval = calendar.dateInterval(of: .year, for: date)!
        self.dateInterval = dateInterval
        
        daysPrayers = (0...)
            .lazy
            .compactMap { day in
                calendar.date(byAdding: .day, value: day, to: dateInterval.start)
            }
            .prefix { $0 < dateInterval.end }
            .map { date in
                DailyPrayers(day: date, calculationParameters: calculationParameters)
            }
    }
}

public extension YearStatistics {
    private static func timeIntervalComparison(from startName: Prayer.Name, to endName: Prayer.Name) -> (DailyPrayers, DailyPrayers) -> Bool {
        return { lhs, rhs in
            lhs.timeInterval(from: startName, to: endName) < rhs.timeInterval(from: startName, to: endName)
        }
    }
    
    func longestDay(from startName: Prayer.Name = .fajr, to endName: Prayer.Name = .maghrib) -> DailyPrayers {
        daysPrayers.max(by: Self.timeIntervalComparison(from: startName, to: endName))!
    }
    
    func shortestDay(from startName: Prayer.Name = .fajr, to endName: Prayer.Name = .maghrib) -> DailyPrayers {
        daysPrayers.min(by: Self.timeIntervalComparison(from: startName, to: endName))!
    }
}

public extension DailyPrayers {
    func timeInterval(from startName: Prayer.Name, to endName: Prayer.Name) -> TimeInterval {
        let endPrayer = prayer(named: endName)
        let startPrayer = prayer(named: startName)
        return endPrayer.start.timeIntervalSince(startPrayer.start)
    }
}
