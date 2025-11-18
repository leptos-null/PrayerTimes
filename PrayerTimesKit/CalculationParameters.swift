//
//  CalculationParameters.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/23/22.
//

import Foundation
import CoreLocation

public struct CalculationParameters: Hashable {
    // This structure is serialized and stored in UserDefaults.
    // For this reason, any changes to the declared properties should
    // be accompanied by a new version in the extension below.
    // A new version entails the following:
    //   assume the current version is `c`, and the new version we're adding is `n`
    //   n = c + 1
    //   Add `vn` as a case to `EncodingVersion`
    //   Create a private struct below `Vc` called Vn that has all the properties that Preferences now has
    //   Update the switch in init(from:) to handle `vn`
    //   Update encode(to:) such that `latest` is of type `Vn` and `vn` is encoded for `.version`
    public struct Configuration: Hashable {
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

extension CalculationParameters.Configuration: Codable {
    private enum CodingKeys: String, CodingKey {
        case version
        case payload
    }
    
    private enum EncodingVersion: Int, Codable, CaseIterable {
        case v0
    }
    
    // Exact copy of properties at v0
    private struct V0: Codable {
        var asrFactor: Double
        var fajrAngle: AngleDegree
        var ishaAngle: AngleDegree
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(EncodingVersion.self, forKey: .version)
        switch version {
        case .v0:
            let versioned: V0 = try container.decode(V0.self, forKey: .payload)
            self.init(asrFactor: versioned.asrFactor, fajrAngle: versioned.fajrAngle, ishaAngle: versioned.ishaAngle)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let latest = V0(asrFactor: asrFactor, fajrAngle: fajrAngle, ishaAngle: ishaAngle)
        
        try container.encode(EncodingVersion.v0, forKey: .version)
        try container.encode(latest, forKey: .payload)
    }
}

// http://praytimes.org/wiki/Calculation_Methods

// This enum is serialized and stored in UserDefaults.
// For this reason, in has certain stability requirements.
//  - case names may not be renamed
//  - a case may be removed, only if it is acceptable that
//    a preference that previously held that value is reset
//    to the default value
//  - this type may not conform to RawRepresentable
public enum CalculationMethod: Hashable, Codable {
    case mwl
    case isna
    case egypt
    case karachi
    case indonesia
    
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
        case .indonesia:
            return .init(asrFactor: 1, fajrAngle: 20, ishaAngle: 18)
        case .custom(let calculationConfiguration):
            return calculationConfiguration
        }
    }
}
