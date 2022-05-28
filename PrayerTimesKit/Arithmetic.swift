//
//  Arithmetic.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation

public typealias AngleDegree = Double
public typealias AngleRadians = Double

typealias JulianDay = Double

enum Arithmetic {
    static let secondsPerMinute: TimeInterval = 60
    static let minutesPerHour: Double = 60
    static let hoursPerDay: Double = 24
    
    static let degreesInCircle: AngleDegree = 360
    static let radiansInCircle: AngleRadians = 2 * .pi
    
    static func degrees(from radians: AngleRadians) -> AngleDegree {
        radians * degreesInCircle / radiansInCircle
    }
    static func radians(from degrees: AngleDegree) -> AngleRadians {
        degrees * radiansInCircle / degreesInCircle
    }
}

extension AngleDegree {
    func radians() -> AngleRadians {
        Arithmetic.radians(from: self)
    }
}

extension AngleRadians {
    func degrees() -> AngleDegree {
        Arithmetic.degrees(from: self)
    }
}

extension JulianDay {
    /// Julian reference date (2000/01/01 12:00:00 UTC)
    static let referenceDay: Self = 2451545.0
    
    /// Julian date at the system reference date
    static let systemReferenceDate: Self = 2451910.5
}

extension Date {
    func julianDate() -> Double {
        timeIntervalSinceReferenceDate / .day + JulianDay.systemReferenceDate
    }
    func julianDay() -> JulianDay {
        (timeIntervalSinceReferenceDate / .day).rounded(.down) + JulianDay.systemReferenceDate
    }
}

func solarApproximationsAccuracyInterval() -> DateInterval {
    // in testing, I observed that solarApproximations.equationOfTime was
    // within 2.75 seconds of Meeus calculations between 1964/06/17 - 2037/10/04
    // we'll say that's the reference date +/- 36 years
    let base: TimeInterval = .day * (JulianDay.referenceDay - JulianDay.systemReferenceDate)
    let magnitude: TimeInterval = .day * 365.25 * 36
    let center = Date(timeIntervalSinceReferenceDate: base)
    return DateInterval(
        start: center.addingTimeInterval(-magnitude),
        end:   center.addingTimeInterval(+magnitude)
    )
}

// https://aa.usno.navy.mil/faq/sun_approx
// more: http://stjarnhimlen.se/comp/ppcomp.html
func solarApproximations(julianDay: JulianDay) -> (declination: AngleRadians, equationOfTime: TimeInterval) {
    // Date(timeIntervalSince1970: 946728000)
    let julianReference = julianDay - JulianDay.referenceDay
    
    // https://astronomy.swin.edu.au/cosmos/A/Anomalistic+Year
    let daysPerAnomalisticYear = 365.25964
    let daysPerTropicalYear = 365.24219
    
    // https://www.physicsforums.com/threads/539999/post-3558510
    let meanAnomalyReference = Arithmetic.radians(from: 357.529)
    let meanSolarLngReference = Arithmetic.radians(from: 280.459)
    let earthEclipticObliquityReference = Arithmetic.radians(from: 23.4393)
    
    let meanAnomalyDailyDelta = Arithmetic.radiansInCircle/daysPerAnomalisticYear // 0.98560027053632315 deg
    let meanSolarLngDailyDelta = Arithmetic.radiansInCircle/daysPerTropicalYear   // 0.98564735908521416 deg
    
    let earthEclipticObliquityDailyDelta = Arithmetic.radiansInCircle/1e9
    
    let meanSolarAnomaly = (meanAnomalyReference + meanAnomalyDailyDelta * julianReference)
        .constrict(to: Arithmetic.radiansInCircle)
    let meanSolarLng = (meanSolarLngReference + meanSolarLngDailyDelta * julianReference)
        .constrict(to: Arithmetic.radiansInCircle)
    let eclipticLng = (meanSolarLng + Arithmetic.radians(from: 1.915) * sin(meanSolarAnomaly) + Arithmetic.radians(from: 0.02) * sin(2 * meanSolarAnomaly))
        .constrict(to: Arithmetic.radiansInCircle)
    
    let eclipticObliquity = earthEclipticObliquityReference - earthEclipticObliquityDailyDelta * julianReference
    let declination = asin(sin(eclipticObliquity) * sin(eclipticLng))
    
    let rightAscension = atan2(
        cos(eclipticObliquity) * sin(eclipticLng),
        cos(eclipticLng)
    )
        .constrict(to: Arithmetic.radiansInCircle)
    
    // "apparent solar time minus mean solar time"
    let equationOfTime: TimeInterval = (meanSolarLng - rightAscension)/Arithmetic.radiansInCircle * .day
    
    // equationOfTime should approximately be bound to (-0.5, +0.5)
    // since `constrict(to:)` constricts values to [0, bound)
    // shift the input by half the range, and then shift the bounded value back
    let halfDay: TimeInterval = .day/2
    let constrictedTime = (equationOfTime + halfDay).constrict(to: .day) - halfDay
    
    return (declination, constrictedTime)
}

extension FloatingPoint {
    func constrict(to bound: Self) -> Self {
        self - bound * (self/bound).rounded(.down)
    }
    
    func signedSqrt() -> Self {
        Self(signOf: self, magnitudeOf: magnitude.squareRoot())
    }
}

extension TimeInterval {
    static let minute = Arithmetic.secondsPerMinute
    static let hour = .minute * Arithmetic.minutesPerHour
    static let day = .hour * Arithmetic.hoursPerDay
}
