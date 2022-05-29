//
//  NowDayView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/28/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

struct NowDayView: View {
    let dailyPrayers: DailyPrayers
    
    @Environment(\.visiblePrayers) private var visiblePrayers
    
    private var prayerStartTimes: [Date] {
        dailyPrayers.ordered
            .filter(visiblePrayers)
            .map { $0.start }
    }
    
    private func nowTime<Schedule: TimelineSchedule, Content>(for timelineContext: TimelineView<Schedule, Content>.Context) -> Date {
#if SCREENSHOT_MODE
        .statusBarDate
#else
        timelineContext.date
#endif
    }
    
    var body: some View {
        TimelineView(MergeTimelineSchedule.merge(.explicit(prayerStartTimes), .everyMinute)) { timelineContext in
            DayView(dailyPrayers: dailyPrayers, nowTime: nowTime(for: timelineContext))
        }
    }
}

struct NowDayView_Previews: PreviewProvider {
    static var previews: some View {
        NowDayView(dailyPrayers: DailyPrayers(day: .now, calculationParameters: CalculationParameters(
            timeZone: TimeZone(identifier: "Asia/Riyadh")!,
            location: CLLocation(latitude: 21.422495, longitude: 39.826158),
            configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18.5, ishaAngle: 19)
        )))
    }
}
