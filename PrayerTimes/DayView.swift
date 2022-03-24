//
//  DayView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/23/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

struct DayView: View {
    let dailyPrayers: DailyPrayers
    let visiblePrayers: Set<Prayer.Name>
    let nowTime: Date?
    
    var body: some View {
        VStack {
            HStack {
                Spacer(minLength: 68)
                DailyPrayersView(dailyPrayers: dailyPrayers, time: nowTime, visiblePrayers: visiblePrayers)
                Spacer(minLength: 68)
            }
            .scenePadding(.vertical)
            Spacer()
            SolarPositionsView(dailyPrayers: dailyPrayers, visiblePrayers: visiblePrayers, currentTime: nowTime)
                .aspectRatio(2, contentMode: .fit)
                .frame(minHeight: 112)
        }
    }
}

struct DayView_Previews: PreviewProvider {
    static var previews: some View {
        DayView(dailyPrayers: DailyPrayers(day: Date(timeIntervalSinceReferenceDate: 667320000), calculationParameters: CalculationParameters(
            timeZone: TimeZone(identifier: "America/Sao_Paulo")!,
            location: CLLocation(latitude: -22.922646, longitude: -43.238628),
            configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        )), visiblePrayers: Set(Prayer.Name.allCases), nowTime: Date(timeIntervalSinceReferenceDate: 667340000))
        
        DayView(dailyPrayers: DailyPrayers(day: Date(timeIntervalSinceReferenceDate: 667320000), calculationParameters: CalculationParameters(
            timeZone: TimeZone(identifier: "America/Sao_Paulo")!,
            location: CLLocation(latitude: -22.922646, longitude: -43.238628),
            configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        )), visiblePrayers: Set(Prayer.Name.allCases), nowTime: nil)
    }
}
