//
//  Arithmetic.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/22/22.
//

import Foundation

typealias AngleDegree = Double
typealias AngleRadians = Double

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

// http://praytimes.org/calculation
func timeIntervalTo(angle: AngleRadians, latitude: AngleRadians, declination: AngleRadians) -> TimeInterval {
    let a = -sin(angle) - sin(latitude) * sin(declination)
    let b = cos(latitude) * cos(declination)
    return acos(a/b) / Arithmetic.radiansInCircle * TimeInterval.day
}

func timeIntervalTo(shadowFactor: Double, latitude: AngleRadians, declination: AngleRadians) -> TimeInterval {
    let length = shadowFactor + tan(latitude - declination)
    let angle = -atan(1/length)
    return timeIntervalTo(angle: angle, latitude: latitude, declination: declination)
}

// based on https://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
func julianDay(calendar: Calendar, date: Date) -> Double {
    assert(calendar.identifier == .gregorian)
    
    var year = calendar.component(.year, from: date)
    var month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    // transform month from [1, 12] to [3, 14]
    if month == 1 || month == 2 {
        year -= 1
        month += 12
    }
    let centuries: Int = year/100
    let leapYears: Int = centuries/4
    let patchedYears: Int = (centuries - leapYears)
    
    let daysPerYear = 365.25
    // https://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/archv011.cgi?read=31650
    let daysPerMonth = Double(365 - 31 - 28)/10.0
    
    let yearsDays: Int = Int(daysPerYear * Double(year + 4716))
    let monthsDays: Int = Int(daysPerMonth * Double(month + 1))
    
    return Double(yearsDays - patchedYears + monthsDays + day) - 1522.5
}

// https://aa.usno.navy.mil/faq/sun_approx
// more: http://stjarnhimlen.se/comp/ppcomp.html
func solarApproximations(julianDay: Double) -> (declination: AngleRadians, equationOfTime: TimeInterval) {
    // Date(timeIntervalSince1970: 946728000)
    let julianReference = julianDay - 2451545.0
    
    // https://astronomy.swin.edu.au/cosmos/A/Anomalistic+Year
    let daysPerAnomalisticYear = 365.25964
    let daysPerTropicalYear = 365.24219
    
    // https://www.physicsforums.com/threads/539999/post-3558510
    let meanAnomalyReference = Arithmetic.radians(from: 357.529)
    let meanSolarLngReference = Arithmetic.radians(from: 280.459)
    let earthEclipticObliquityReference = Arithmetic.radians(from: 23.4393)
    
    let meanAnomalyDailyDelta = Arithmetic.radiansInCircle/daysPerAnomalisticYear // 0.98560027053632315 deg
    let meanSolarLngDailyDelta = Arithmetic.radiansInCircle/daysPerTropicalYear   // 0.98564735908521416 deg
    
    let meanSolarAnomaly = (meanAnomalyReference + meanAnomalyDailyDelta * julianReference)
        .constrict(to: Arithmetic.radiansInCircle)
    let meanSolarLng = (meanSolarLngReference + meanSolarLngDailyDelta * julianReference)
        .constrict(to: Arithmetic.radiansInCircle)
    let eclipticLng = (meanSolarLng + Arithmetic.radians(from: 1.915) * sin(meanSolarAnomaly) + Arithmetic.radians(from: 0.02) * sin(2 * meanSolarAnomaly))
        .constrict(to: Arithmetic.radiansInCircle)
    
    let eclipticObliquity = earthEclipticObliquityReference - Arithmetic.radians(from: 0.00000036) * julianReference
    let declination = asin(sin(eclipticObliquity) * sin(eclipticLng))
    
    let rightAscension = atan2(
        cos(eclipticObliquity) * sin(eclipticLng),
        cos(eclipticLng)
    )
        .constrict(to: Arithmetic.radiansInCircle)
    
    // "apparent solar time minus mean solar time"
    let equationOfTime = (meanSolarLng - rightAscension)/Arithmetic.radiansInCircle * TimeInterval.day
    
    return (declination, equationOfTime)
}

extension FloatingPoint {
    func constrict(to bound: Self) -> Self {
        self - bound * (self/bound).rounded(.down)
    }
    
    func signedSqrt() -> Self {
        .init(signOf: self, magnitudeOf: magnitude.squareRoot())
    }
}

extension TimeInterval {
    static let minute = Arithmetic.secondsPerMinute
    static let hour = .minute * Arithmetic.minutesPerHour
    static let day = .hour * Arithmetic.hoursPerDay
}
