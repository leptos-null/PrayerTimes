//
//  DailyPrayers.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation
import CoreLocation

public struct DailyPrayers {
    public let timezone: TimeZone
    public let location: CLLocation
    public let configuration: CalculationConfiguration
    
    public let qiyam: Prayer
    public let fajr: Prayer
    public let dhuhr: Prayer
    public let asr: Prayer
    public let maghrib: Prayer
    public let isha: Prayer
    
    public init(day: Date, timezone: TimeZone, location: CLLocation, configuration: CalculationConfiguration) {
        let timezoneSeconds = timezone.secondsFromGMT(for: day)
        var calculationCalendar = Calendar(identifier: .gregorian)
        guard let frozenTimezone = TimeZone(secondsFromGMT: timezoneSeconds) else { fatalError() }
        calculationCalendar.timeZone = frozenTimezone
        
        let dayStart = calculationCalendar.startOfDay(for: day)
        
        let julianDay = julianDay(calendar: calculationCalendar, date: day)
        let (declination, equationOfTime) = solarApproximations(julianDay: julianDay)
        
        let coordinate = location.coordinate
        let latitude = Arithmetic.radians(from: coordinate.latitude)
        
        // http://praytimes.org/calculation
        let solarNoonTime: TimeInterval = (TimeInterval.day/2 - coordinate.longitude/Arithmetic.degreesInCircle * TimeInterval.day - equationOfTime)
            .constrict(to: TimeInterval.day) + TimeInterval(timezoneSeconds)
        
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
        
        let nightEnd = fajr.addingTimeInterval(.day)
        
        self.timezone = timezone
        self.location = location
        self.configuration = configuration
        
        self.qiyam = Prayer(.qiyam, start: qiyam, end: fajr)
        self.fajr = Prayer(.fajr, start: fajr, end: sunrise)
        self.dhuhr = Prayer(.dhuhr, start: dhuhr, end: asr)
        self.asr = Prayer(.asr, start: asr, end: maghrib)
        self.maghrib = Prayer(.maghrib, start: maghrib, end: isha)
        self.isha = Prayer(.isha, start: isha, end: nightEnd)
    }
}

extension DailyPrayers {
    public var ordered: [Prayer] {
        [
            qiyam,
            fajr,
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
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}
