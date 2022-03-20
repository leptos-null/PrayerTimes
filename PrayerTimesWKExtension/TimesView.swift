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
    let visiblePrayers: Set<Prayer.Name>
    let locationTitle: String
    
    var body: some View {
        ScrollView {
            TimelineView(.prayers(with: calculationParameters, visiblePrayers: visiblePrayers)) { timelineContext in
                VStack(alignment: .leading, spacing: 4) {
                    // this label is effectively static and doesn't need to be in the TimelineView
                    //   but including it inside the TimelineView simplifies layout
                    Text(locationTitle)
                        .font(.headline)
                    RollingPrayersView(startDate: timelineContext.date, calculationParameters: calculationParameters, visiblePrayers: visiblePrayers)
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
    private let nextPrayer: Prayer?
    
    init(startDate: Date, calculationParameters: CalculationParameters, visiblePrayers: Set<Prayer.Name>, maxPrayers: Int = 6) {
        guard !visiblePrayers.isEmpty else {
            todayPrayers = []
            tomorrowPrayers = []
            currentPrayer = nil
            nextPrayer = nil
            return
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calculationParameters.timeZone
        
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let today = DailyPrayers(day: startDate, calculationParameters: calculationParameters)
        let tomorrow = DailyPrayers(day: tomorrowDate, calculationParameters: calculationParameters)
        
        let sortedFilter = visiblePrayers.sorted()
        
        let todayFiltered = today.ordered.filter(visiblePrayers)
        if let activePrayer = todayFiltered.activePrayer(for: startDate) {
            let suffix = todayFiltered.drop { $0 != activePrayer }
            todayPrayers = Array(suffix)
            
            let currentNameIndex = sortedFilter.firstIndex(of: activePrayer.name)!
            if currentNameIndex != sortedFilter.indices.last {
                let nextNameIndex = sortedFilter.index(after: currentNameIndex)
                nextPrayer = today.prayer(named: sortedFilter[nextNameIndex])
            } else {
                nextPrayer = tomorrow.prayer(named: sortedFilter.first!)
            }
            currentPrayer = activePrayer
        } else {
            todayPrayers = today.ordered.filter(visiblePrayers)
            nextPrayer = today.prayer(named: sortedFilter.first!)
            currentPrayer = nil
        }
        
        let tomorrowCount = maxPrayers - todayPrayers.count
        if tomorrowCount > 0 {
            tomorrowPrayers = Array(tomorrow.ordered.filter(visiblePrayers).prefix(tomorrowCount))
        } else {
            tomorrowPrayers = []
        }
    }
    
    var body: some View {
        if let nextPrayer = nextPrayer {
            Text("\(nextPrayer.name.localized) starts in:")
            Text(nextPrayer.start, style: .timer)
        }
        
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
        ), visiblePrayers: Set(Prayer.Name.allCases), locationTitle: "Mecca, Makkah")
    }
}
