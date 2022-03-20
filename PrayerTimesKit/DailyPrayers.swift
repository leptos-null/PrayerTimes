//
//  DailyPrayers.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation
import CoreLocation

public struct DailyPrayers {
    public let calculationParameters: CalculationParameters
    
    public let qiyam: Prayer
    public let fajr: Prayer
    public let sunrise: Prayer
    public let dhuhr: Prayer
    public let asr: Prayer
    public let maghrib: Prayer
    public let isha: Prayer
    
    public init(day: Date, calculationParameters: CalculationParameters) {
        let timeZone = calculationParameters.timeZone
        let location = calculationParameters.location
        let configuration = calculationParameters.configuration
        
        var calculationCalendar = Calendar(identifier: .gregorian)
        calculationCalendar.timeZone = timeZone
        
        let dayStart = calculationCalendar.startOfDay(for: day)
        
        let julianDay = dayStart.julianDay()
        let (declination, equationOfTime) = solarApproximations(julianDay: julianDay)
        
        let coordinate = location.coordinate
        let latitude = Arithmetic.radians(from: coordinate.latitude)
        
        // http://praytimes.org/calculation
        let solarNoonTime: TimeInterval = (TimeInterval.day/2 - coordinate.longitude/Arithmetic.degreesInCircle * TimeInterval.day - equationOfTime)
            .constrict(to: TimeInterval.day) + TimeInterval(timeZone.secondsFromGMT(for: dayStart))
        
        let solarPosition = SolarPosition(latitude: latitude, declination: declination)
        
        let altitude = (location.verticalAccuracy > 0) ? location.altitude : 0
        let atmosphericRefraction: AngleDegree = 0.833 + 0.0347 * altitude.signedSqrt()
        let horizonOffset = solarPosition.timeIntervalTo(depressionAngle: atmosphericRefraction.radians())
        
        let sunriseTime = solarNoonTime - horizonOffset
        let sunsetTime = solarNoonTime + horizonOffset
        
        let fajrTime = solarNoonTime - solarPosition.timeIntervalTo(depressionAngle: configuration.fajrAngle.radians())
        let ishaTime = solarNoonTime + solarPosition.timeIntervalTo(depressionAngle: configuration.ishaAngle.radians())
        
        let asrTime = solarNoonTime + solarPosition.timeIntervalTo(shadowFactor: configuration.asrFactor)
        
        let yesterdayIshaTime = ishaTime - .day // reasonable estimation of Isha time yesterday
        let qiyamTime = (fajrTime - yesterdayIshaTime) * 2/3.0 + yesterdayIshaTime
        
        let qiyam = dayStart.addingTimeInterval(qiyamTime)
        let fajr = dayStart.addingTimeInterval(fajrTime)
        let sunrise = dayStart.addingTimeInterval(sunriseTime)
        let dhuhr = dayStart.addingTimeInterval(solarNoonTime)
        let asr = dayStart.addingTimeInterval(asrTime)
        let maghrib = dayStart.addingTimeInterval(sunsetTime)
        let isha = dayStart.addingTimeInterval(ishaTime)
        
        self.calculationParameters = calculationParameters
        
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
}
