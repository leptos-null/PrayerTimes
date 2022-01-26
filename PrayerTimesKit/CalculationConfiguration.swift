//
//  CalculationConfiguration.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/23/22.
//

import Foundation

public struct CalculationConfiguration {
    public let asrFactor: Double
    public let fajrAngle: AngleDegree
    public let ishaAngle: AngleDegree
}

// http://praytimes.org/wiki/Calculation_Methods
public extension CalculationConfiguration {
    static let mwl = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
    static let isna = CalculationConfiguration(asrFactor: 1, fajrAngle: 15, ishaAngle: 15)
}
