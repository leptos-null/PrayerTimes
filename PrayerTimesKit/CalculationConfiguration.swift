//
//  CalculationConfiguration.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/23/22.
//

import Foundation

struct CalculationConfiguration {
    let asrFactor: Double
    let fajrAngle: AngleDegree
    let ishaAngle: AngleDegree
}

// http://praytimes.org/wiki/Calculation_Methods
extension CalculationConfiguration {
    static let mwl = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
    static let isna = CalculationConfiguration(asrFactor: 1, fajrAngle: 15, ishaAngle: 15)
}
