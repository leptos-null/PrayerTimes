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
        .environment(\.timeZone, dailyPrayers.timeZone)
    }
}

extension Prayer: Identifiable {
    public var id: Prayer { self }
}

struct DailyPrayersView_Previews: PreviewProvider {
    static var previews: some View {
        DailyPrayersView(dailyPrayers: DailyPrayers(
            day: Date(timeIntervalSinceReferenceDate: 664581600),
            timeZone: TimeZone(identifier: "Africa/Johannesburg")!,
            location: CLLocation(latitude: -29.856687, longitude: 31.017086),
            configuration: CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        ))
    }
}
