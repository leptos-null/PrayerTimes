//
//  CalculationParameters.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/23/22.
//

import Foundation
import CoreLocation

public struct CalculationParameters: Hashable {
    public struct Configuration: Hashable, Codable {
        public var asrFactor: Double
        public var fajrAngle: AngleDegree
        public var ishaAngle: AngleDegree
        
        public init(asrFactor: Double, fajrAngle: AngleDegree, ishaAngle: AngleDegree) {
            self.asrFactor = asrFactor
            self.fajrAngle = fajrAngle
            self.ishaAngle = ishaAngle
        }
    }
    
    public var timeZone: TimeZone
    public var location: CLLocation
    public var configuration: Configuration
    
    public init(timeZone: TimeZone, location: CLLocation, configuration: Configuration) {
        self.timeZone = timeZone
        self.location = location
        self.configuration = configuration
    }
}

// http://praytimes.org/wiki/Calculation_Methods
public enum CalculationMethod: Hashable, Codable {
    case mwl
    case isna
    case egypt
    case karachi
    
    case custom(CalculationParameters.Configuration)
    
    public var calculationConfiguration: CalculationParameters.Configuration {
        switch self {
        case .mwl:
            return .init(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        case .isna:
            return .init(asrFactor: 1, fajrAngle: 15, ishaAngle: 15)
        case .egypt:
            return .init(asrFactor: 1, fajrAngle: 19.5, ishaAngle: 17.5)
        case .karachi:
            return .init(asrFactor: 1, fajrAngle: 18, ishaAngle: 18)
        case .custom(let calculationConfiguration):
            return calculationConfiguration
        }
    }
}
