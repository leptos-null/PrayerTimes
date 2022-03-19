//
//  TimesView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/18/22.
//

import SwiftUI
import PrayerTimesKit

struct TimesView: View {
    let calculationParameters: CalculationParameters
    let locationTitle: String
    
    var body: some View {
        ScrollView {
            TimelineView(.prayers(with: calculationParameters)) { timelineContext in
                VStack(alignment: .leading, spacing: 4) {
                    // this label is effectively static and doesn't need to be in the TimelineView
                    //   but including it inside the TimelineView simplifies layout
                    Text(locationTitle)
                        .font(.headline)
                    RollingPrayersView(startDate: timelineContext.date, calculationParameters: calculationParameters)
                        .environment(\.timeZone, calculationParameters.timeZone)
                }
            }
        }
    }
}

struct RollingPrayersView: View {
    let todayPrayers: [Prayer]
    let tomorrowPrayers: [Prayer]
    
    private let currentPrayer: Prayer?
    private let nextPrayer: Prayer
    
    init(startDate: Date, calculationParameters: CalculationParameters, maxPrayers: Int = 6) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calculationParameters.timeZone
        
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let today = DailyPrayers(day: startDate, calculationParameters: calculationParameters)
        let tomorrow = DailyPrayers(day: tomorrowDate, calculationParameters: calculationParameters)
        
        if let currentPrayer = today.activePrayer(for: startDate) {
            let suffix = today.ordered.drop { $0 != currentPrayer }
            todayPrayers = Array(suffix)
            
            if currentPrayer.name != .isha {
                nextPrayer = today.prayer(named: currentPrayer.name.next)
            } else {
                nextPrayer = tomorrow.qiyam
            }
            self.currentPrayer = currentPrayer
        } else {
            todayPrayers = today.ordered
            nextPrayer = today.qiyam
            currentPrayer = nil
        }
        
        let tomorrowCount = maxPrayers - todayPrayers.count
        if tomorrowCount > 0 {
            tomorrowPrayers = Array(tomorrow.ordered.prefix(tomorrowCount))
        } else {
            tomorrowPrayers = []
        }
    }
    
    var body: some View {
        Text("\(nextPrayer.name.localized) starts in:")
        Text(nextPrayer.start, style: .timer)
        
        if todayPrayers.count > 0 {
            PrayerListView(prayers: todayPrayers, current: currentPrayer)
        }
        if tomorrowPrayers.count > 0 {
            Text("Tomorrow")
                .font(.headline)
            PrayerListView(prayers: tomorrowPrayers, current: nil)
        }
    }
}

struct PrayerListView: View {
    let prayers: [Prayer]
    let current: Prayer?
    
    var body: some View {
        ForEach(prayers) { prayer in
            HStack {
                Text(prayer.name.localized)
                    .fontWeight((prayer == current) ? .semibold : .regular)
                Spacer()
                
                Text(prayer.start, style: .time)
                    .fontWeight((prayer == current) ? .semibold : .regular)
            }
            .padding()
            .frame(minHeight: 44)
            .background(.quaternary)
            .cornerRadius(8)
        }
    }
}

struct TimesView_Previews: PreviewProvider {
    static var previews: some View {
        TimesView(calculationParameters: CalculationParameters(
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            location: CLLocation(latitude: 21.422495, longitude: 39.826158),
            configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18.5, ishaAngle: 19)
        ), locationTitle: "Mecca, Makkah")
    }
}
