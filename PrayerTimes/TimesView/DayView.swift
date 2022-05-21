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

struct DayView<Header: View>: View {
    let dailyPrayers: DailyPrayers
    let visiblePrayers: Set<Prayer.Name>
    let nowTime: Date?
    private let headerBuilder: (Date) -> Header
    
    init(dailyPrayers: DailyPrayers, visiblePrayers: Set<Prayer.Name>, nowTime: Date? = nil, @ViewBuilder headerBuilder: @escaping (Date) -> Header) {
        self.dailyPrayers = dailyPrayers
        self.visiblePrayers = visiblePrayers
        self.nowTime = nowTime
        self.headerBuilder = headerBuilder
    }
    
    init(dailyPrayers: DailyPrayers, visiblePrayers: Set<Prayer.Name>, nowTime: Date? = nil) where Header == DateTitle {
        self.init(dailyPrayers: dailyPrayers, visiblePrayers: visiblePrayers, nowTime: nowTime, headerBuilder: DateTitle.init(date:))
    }
    
    var body: some View {
        VStack {
            DailyPrayersView(dailyPrayers: dailyPrayers, time: nowTime, visiblePrayers: visiblePrayers, header: headerBuilder)
                .scenePadding()
            
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
