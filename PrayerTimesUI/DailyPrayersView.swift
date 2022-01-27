//
//  DailyPrayersView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 1/26/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit

public struct DailyPrayersView: View {
    public let dailyPrayers: DailyPrayers
    let current: Prayer?
    
    public init(dailyPrayers: DailyPrayers, time: Date? = nil) {
        self.dailyPrayers = dailyPrayers
        
        if let time = time {
            current = dailyPrayers.activePrayer(for: time)
        } else {
            current = nil
        }
    }
    
    public var body: some View {
        VStack {
            Text(dailyPrayers.dhuhr.start, style: .date)
                .font(.headline)
            ForEach(dailyPrayers.ordered) { prayer in
                HStack {
                    Text(prayer.name.localized)
                        .fontWeight((prayer == current) ? .semibold : .regular)
                    Spacer()
                    
                    Text(prayer.start, style: .time)
                        .fontWeight((prayer == current) ? .semibold : .regular)
                }
                .padding(.vertical, 1)
            }
        }
        .environment(\.timeZone, dailyPrayers.timezone)
    }
}

extension Prayer: Identifiable {
    public var id: Prayer { self }
}

extension Prayer.Name {
    var localized: String {
        switch self {
        case .qiyam:   return NSLocalizedString("PRAYER_NAME_QIYAM",   value: "Qiyam",   comment: "Name for Qiyam prayer")
        case .fajr:    return NSLocalizedString("PRAYER_NAME_FAJR",    value: "Fajr",    comment: "Name for Fajr prayer")
        case .sunrise: return NSLocalizedString("PRAYER_NAME_SUNRISE", value: "Sunrise", comment: "Name for sunrise")
        case .dhuhr:   return NSLocalizedString("PRAYER_NAME_DHUHR",   value: "Dhuhr",   comment: "Name for Dhuhr prayer")
        case .asr:     return NSLocalizedString("PRAYER_NAME_ASR",     value: "Asr",     comment: "Name for Asr prayer")
        case .maghrib: return NSLocalizedString("PRAYER_NAME_MAGHRIB", value: "Maghrib", comment: "Name for Maghrib prayer")
        case .isha:    return NSLocalizedString("PRAYER_NAME_ISHA",    value: "Isha",    comment: "Name for Isha prayer")
        }
    }
}

struct DailyPrayersView_Previews: PreviewProvider {
    static var previews: some View {
        DailyPrayersView(dailyPrayers: DailyPrayers(
            day: Date(timeIntervalSinceReferenceDate: 664581600),
            timezone: TimeZone(identifier: "Africa/Johannesburg")!,
            location: CLLocation(latitude: -29.856687, longitude: 31.017086),
            configuration: CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        ))
    }
}
