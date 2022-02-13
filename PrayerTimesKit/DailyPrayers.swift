//
//  DailyPrayers.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation
import CoreLocation

public struct DailyPrayers {
    public let timeZone: TimeZone
    public let location: CLLocation
    public let configuration: CalculationConfiguration
    
    public let qiyam: Prayer
    public let fajr: Prayer
    public let sunrise: Prayer
    public let dhuhr: Prayer
    public let asr: Prayer
    public let maghrib: Prayer
    public let isha: Prayer
    
    public init(day: Date, timeZone: TimeZone, location: CLLocation, configuration: CalculationConfiguration) {
        let timeZoneSeconds = timeZone.secondsFromGMT(for: day)
        var calculationCalendar = Calendar(identifier: .gregorian)
        guard let frozenTimezone = TimeZone(secondsFromGMT: timeZoneSeconds) else { fatalError() }
        calculationCalendar.timeZone = frozenTimezone
        
        let dayStart = calculationCalendar.startOfDay(for: day)
        
        let julianDay = julianDay(calendar: calculationCalendar, date: day)
        let (declination, equationOfTime) = solarApproximations(julianDay: julianDay)
        
        let coordinate = location.coordinate
        let latitude = Arithmetic.radians(from: coordinate.latitude)
        
        // http://praytimes.org/calculation
        let solarNoonTime: TimeInterval = (TimeInterval.day/2 - coordinate.longitude/Arithmetic.degreesInCircle * TimeInterval.day - equationOfTime)
            .constrict(to: TimeInterval.day) + TimeInterval(timeZoneSeconds)
        
        let solarPosition = SolarPosition(latitude: latitude, declination: declination)
        
        let altitude = (location.verticalAccuracy > 0) ? location.altitude : 0
        let atmosphericRefraction: AngleDegree = 0.833 + 0.0347 * altitude.signedSqrt()
        let horizonOffset = solarPosition.timeIntervalTo(angle: atmosphericRefraction.radians())
        
        let sunriseTime = solarNoonTime - horizonOffset
        let sunsetTime = solarNoonTime + horizonOffset
        
        let fajrTime = solarNoonTime - solarPosition.timeIntervalTo(angle: configuration.fajrAngle.radians())
        let ishaTime = solarNoonTime + solarPosition.timeIntervalTo(angle: configuration.ishaAngle.radians())
        
        let asrTime = solarNoonTime + solarPosition.timeIntervalTo(shadowFactor: configuration.asrFactor)
        
        let qiyamTime = (fajrTime + .day - ishaTime) * 2/3.0 + ishaTime - .day
        
        let qiyam = dayStart.addingTimeInterval(qiyamTime)
        let fajr = dayStart.addingTimeInterval(fajrTime)
        let sunrise = dayStart.addingTimeInterval(sunriseTime)
        let dhuhr = dayStart.addingTimeInterval(solarNoonTime)
        let asr = dayStart.addingTimeInterval(asrTime)
        let maghrib = dayStart.addingTimeInterval(sunsetTime)
        let isha = dayStart.addingTimeInterval(ishaTime)
        
        self.timeZone = timeZone
        self.location = location
        self.configuration = configuration
        
        self.qiyam = Prayer(.qiyam, start: qiyam)
        self.sunrise = Prayer(.sunrise, start: sunrise)
        self.fajr = Prayer(.fajr, start: fajr)
        self.dhuhr = Prayer(.dhuhr, start: dhuhr)
        self.asr = Prayer(.asr, start: asr)
        self.maghrib = Prayer(.maghrib, start: maghrib)
        self.isha = Prayer(.isha, start: isha)
    }
}

extension DailyPrayers {
    public var ordered: [Prayer] {
        [
            qiyam,
            fajr,
            sunrise,
            dhuhr,
            asr,
            maghrib,
            isha
        ]
    }
    
    public func prayer(named name: Prayer.Name) -> Prayer {
        switch name {
        case .qiyam: return qiyam
        case .fajr: return fajr
        case .sunrise: return sunrise
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
    
    public func activePrayer(for date: Date) -> Prayer? {
        ordered.last { date.timeIntervalSince($0.start) > 0 }
    }
}
