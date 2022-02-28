//
//  TimesView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/27/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

struct TimesView: View {
    let calculationParameters: CalculationParameters
    let locationTitle: String
    
    private let calendar: Calendar
    
    init(calculationParameters: CalculationParameters, locationTitle: String) {
        self.calculationParameters = calculationParameters
        self.locationTitle = locationTitle
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calculationParameters.timeZone
        self.calendar = calendar
    }
    
    var body: some View {
        TabView {
            // these need to seperate otherwise the TabView is only given 1 view to layout
            // if the TabView is inside the TimelineView, the entire timeline is computed
            TimelineView(.everyDay(using: calendar)) { dayTimelineContext in
                NowDayView(dailyPrayers: DailyPrayers(day: dayTimelineContext.date, calculationParameters: calculationParameters), locationTitle: locationTitle)
            }
            TimelineView(.everyDay(using: calendar)) { dayTimelineContext in
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: dayTimelineContext.date) {
                    DayView(dailyPrayers: DailyPrayers(day: nextDay, calculationParameters: calculationParameters), nowTime: nil, locationTitle: locationTitle)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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