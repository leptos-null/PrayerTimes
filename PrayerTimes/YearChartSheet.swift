//
//  YearChartSheet.swift
//  PrayerTimes
//
//  Created by Leptos on 7/21/24.
//

import SwiftUI
import PrayerTimesKit
import PrayerTimesUI

@available(iOS 16.0, *)
struct YearChartSheet: View {
    let date: Date
    let calculationParameters: CalculationParameters
    let locationTitle: String
    
    @Environment(\.calendar) private var calendar
    @Environment(\.visiblePrayers) private var visiblePrayers
    @Environment(\.dismiss) private var dismiss
    
    private var data: YearChartData {
        var calendarCopy = calendar
        calendarCopy.timeZone = calculationParameters.timeZone
        
        let statistics = YearStatistics(date: date, calendar: calendarCopy, calculationParameters: calculationParameters)
        return YearChartData(statistics: statistics, visiblePrayers: visiblePrayers)
    }
    
    var body: some View {
        NavigationStack {
            YearChart(data: data, locationTitle: locationTitle)
                .ignoresSafeArea(.container, edges: .top)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done", role: .cancel) {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)
                        .font(.headline)
                    }
                }
        }
    }
}
