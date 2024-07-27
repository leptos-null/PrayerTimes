//
//  PrayerNameIntentValue.swift
//  PrayerTimesIntents
//
//  Created by Leptos on 7/27/24.
//

import Foundation
import AppIntents
import PrayerTimesKit

enum PrayerNameIntentValue: String, AppEnum {
    case qiyam
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
    
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer"
    
    // this must be compile-time constant since it's processed at compile-time
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .qiyam: "Qiyam",
        .fajr: "Fajr",
        .sunrise: "Sunrise",
        .dhuhr: "Dhuhr",
        .asr: "Asr",
        .maghrib: "Maghrib",
        .isha: "Isha",
    ]
}

extension Prayer.Name {
    init(intentValue: PrayerNameIntentValue) {
        self = switch intentValue {
        case .qiyam: .qiyam
        case .fajr: .fajr
        case .sunrise: .sunrise
        case .dhuhr: .dhuhr
        case .asr: .asr
        case .maghrib: .maghrib
        case .isha: .isha
        }
    }
}
