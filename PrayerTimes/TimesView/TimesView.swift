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
    
    private func nowTime<Schedule: TimelineSchedule, Content>(for timelineContext: TimelineView<Schedule, Content>.Context) -> Date {
#if SCREENSHOT_MODE
        .statusBarDate
#else
        timelineContext.date
#endif
    }
    
    private func dailyPrayers(for date: Date) -> DailyPrayers {
        DailyPrayers(day: date, calculationParameters: calculationParameters)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            LocationHeader(title: locationTitle)
                .padding(.bottom, 16)
            TabView {
                // these need to seperate otherwise the TabView is only given 1 view to layout
                // if the TabView is inside the TimelineView, the entire timeline is computed
                TimelineView(.everyDay(using: calendar)) { dayTimelineContext in
                    NowDayView(dailyPrayers: dailyPrayers(for: nowTime(for: dayTimelineContext)))
                }
                TimelineView(.everyDay(using: calendar)) { dayTimelineContext in
                    if let nextDay = calendar.date(byAdding: .day, value: 1, to: nowTime(for: dayTimelineContext)) {
                        DayView(dailyPrayers: dailyPrayers(for: nextDay))
                    }
                }
                ScrubDayView(calculationParameters: calculationParameters, locationTitle: locationTitle)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

#if SCREENSHOT_MODE
extension Date {
    // based on iOS 17 marketing material
    static let statusBarDate = try! Date.ISO8601FormatStyle.iso8601.parse("2023-09-12T16:41:30Z")
}
#endif

struct TimesView_Previews: PreviewProvider {
    static var previews: some View {
        TimesView(calculationParameters: CalculationParameters(
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            location: CLLocation(latitude: 21.422495, longitude: 39.826158),
            configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18.5, ishaAngle: 19)
        ), locationTitle: "Mecca, Makkah")
    }
}
