//
//  SolarPosition.swift
//  PrayerTimesKit
//
//  Created by Leptos on 3/31/22.
//

import Foundation

// https://www.astronomycenter.net/pdf/mohamoud_2017.pdf
struct SolarPosition {
    /// Latitude of the observer
    let latitude: AngleRadians
    /// Declination of the Sun
    let declination: AngleRadians
    
    private let sin_latitude: Double
    private let sin_declination: Double
    private let cos_latitude: Double
    private let cos_declination: Double
    
    init(latitude: AngleRadians, declination: AngleRadians) {
        self.latitude = latitude
        self.declination = declination
        
        self.sin_latitude = sin(latitude)
        self.sin_declination = sin(declination)
        self.cos_latitude = cos(latitude)
        self.cos_declination = cos(declination)
    }
    
    func timeIntervalTo(depressionAngle: AngleRadians) -> TimeInterval {
        return timeIntervalTo(elevationAngle: -depressionAngle)
    }
    
    func timeIntervalTo(elevationAngle: AngleRadians) -> TimeInterval {
        let a = sin(elevationAngle) - sin_latitude * sin_declination
        let b = cos_latitude * cos_declination
        let q = max(-1, min(a/b, 1)) // restrict `q` to the domain of `acos`
        return acos(q) / Arithmetic.radiansInCircle * .day
    }
    
    func timeIntervalTo(shadowFactor: Double) -> TimeInterval {
        let length = shadowFactor + tan(abs(latitude - declination))
        let angle = atan(1/length)
        return timeIntervalTo(elevationAngle: angle)
    }
}
