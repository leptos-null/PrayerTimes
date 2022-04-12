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

extension Date {
    func julianDate() -> Double {
        timeIntervalSinceReferenceDate / .day + 2451910.5
    }
    func julianDay() -> JulianDay {
        (timeIntervalSinceReferenceDate / .day).rounded(.down) + 2451910.5
    }
}

// Thanks to "Astronomical Algorithms (Seconds Edition)" by Jean Meeus
// referred to by https://squarewidget.com/solar-coordinates/
func solarApproximations(julianDay: JulianDay) -> (declination: AngleRadians, equationOfTime: TimeInterval) {
    /// T (Meeus 25.1)
    let time: Double = (julianDay - 2451545.0)/36525
    /// T^2
    let timeSq: Double = (time * time)
    
    /// L_0 (Meeus 25.2 and 28.2)
    let meanSolarLng = (280.46646 + 36000.76982779 * time + 0.0003032028 * timeSq)
        .constrict(to: Arithmetic.degreesInCircle).radians()
    
    /// M (Meeus 25.3)
    let meanSolarAnomaly = (357.52911 + 35999.05029 * time - 0.0001537 * timeSq)
        .constrict(to: Arithmetic.degreesInCircle).radians()
    
    /// C (Meeus unlabeled, page 164)
    let center = (1.914602 - 0.004187 * time - 0.000014 * timeSq) * sin(1 * meanSolarAnomaly)
    + (0.019993 - 0.0000101 * time) * sin(2 * meanSolarAnomaly)
    + (0.000289) * sin(3 * meanSolarAnomaly)
    
    /// odot (Meeus unlabeled, page 164)
    let trueSolarLng = meanSolarLng + center.radians()
    
    /// U
    let U: Double = time/100
    let eclipticCoefficients: [AngleDegree] = [ 23.439291, -1.3002583, -1.55, 1999.25, -51.38, -249.67, -39.05, 7.12, 27.87, 5.79, 2.45 ]
    /// epsilon_0 (Meeus 22.3)
    let meanEclipticObliquity: AngleDegree = eclipticCoefficients.enumerated().reduce(into: 0) { partialResult, zipped in
        partialResult += zipped.element * pow(U, Double(zipped.offset))
    }
    
    /// Omega (Meeus unlabeled, page 144)
    let omega = (125.04452 - 1934.136261 * time + 0.0020708 * timeSq)
        .constrict(to: Arithmetic.degreesInCircle).radians()
    /// Delta psi (Meeus unlabeled, page 144)
    let longitudeNutation: AngleRadians = -0.000083388 * sin(omega) - 0.0000064 * sin(2 * meanSolarLng)
    /// Delta epsilon (Meeus unlabeled, page 144)
    let obliquityNutation: AngleRadians = 0.0000446 * cos(omega) + 0.0000028 * cos(2 * meanSolarLng)
    /// epsilon (Meeus unlabeled, page 147)
    let trueEclipticObliquity: AngleRadians = meanEclipticObliquity.radians() + obliquityNutation
    /// alpha (Meeus 25.6)
    let rightAscension: AngleRadians = atan2(
        cos(trueEclipticObliquity) * sin(trueSolarLng),
        cos(trueSolarLng)
    )
        .constrict(to: Arithmetic.radiansInCircle)
    /// delta (Meeus 25.7)
    let declination: AngleRadians = asin(sin(trueEclipticObliquity) * sin(trueSolarLng))
    
    let longitudeAberration: AngleRadians = Arithmetic.radians(from: 0.0057183)
    /// E (Meeus 28.1)
    let equationOfTime: TimeInterval = (meanSolarLng - longitudeAberration - rightAscension + longitudeNutation * cos(trueEclipticObliquity))/Arithmetic.radiansInCircle * .day
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
