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
    
    private var prayerStartTimes: [Date] {
        dailyPrayers.ordered.map { $0.start }
    }
    
    var body: some View {
        TimelineView(ZipTimelineSchedule.zip(.explicit(prayerStartTimes), .everyMinute)) { timelineContext in
            DayView(dailyPrayers: dailyPrayers, nowTime: timelineContext.date)
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
