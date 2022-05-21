//
//  ScrubDayView.swift
//  PrayerTimes
//
//  Created by Leptos on 5/16/22.
//

import SwiftUI
import PrayerTimesKit

struct ScrubDayView: View {
    let calculationParameters: CalculationParameters
    let visiblePrayers: Set<Prayer.Name>
    
    @State private var date: Date = .now
    
    var body: some View {
        // TODO: Improve macOS and trackpad experience
        DayView(dailyPrayers: DailyPrayers(day: date, calculationParameters: calculationParameters), visiblePrayers: visiblePrayers) { date in
            DatePicker("Day", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
#if !targetEnvironment(macCatalyst)
                .id(date) // causes DatePicker to re-layout for each date, otherwise the width stays the same as it was for the initial date
                .padding(.top, -8) // remove top padding in an attempt to align first baseline with DateTitle
#endif
        }
        .frame(maxWidth: .infinity, alignment: .center) // use the full available width so the scrubber is on the apparent trailing edge
        .overlay(alignment: .trailing) {
            DateScrubber(date: $date)
        }
    }
}

private struct DateScrubber: View {
    @Binding var date: Date
    @Environment(\.calendar) private var calendar
    
    @StateObject private var rateLimiter = RealTimeRateLimit(interval: .microseconds(62500)) // 0.0625 seconds, i.e. 1/16th of a second
    
    private var era: Int {
        calendar.component(.era, from: date)
    }
    
    private var year: Int {
        calendar.component(.year, from: date)
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            let height = geometryProxy.size.height * 0.6
            HStack {
                Spacer()
                ScaledMonthStack(calendar: calendar, era: era, year: year, height: height)
                    .equatable()
                    .contentShape(.interaction, Rectangle())
                    .onDragGesture(minimumDistance: 0) { dragValue in
                        let previousDate = date
                        guard let yearInterval = calendar.dateInterval(of: .year, for: previousDate) else { return }
                        
                        let fraction = dragValue.location.y / height
                        let propose = yearInterval.start.addingTimeInterval(yearInterval.duration * fraction)
                        
                        // dateInterval is inclusive- remove the last second that may bump into the next year
                        let endDate = yearInterval.end.addingTimeInterval(-1)
                        date = max(yearInterval.start, min(propose, endDate))
                        
                        if !calendar.isDate(date, inSameDayAs: previousDate), rateLimiter.permitted() {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            }
        }
    }
}

private struct ScaledMonthStack: View, Equatable {
    let calendar: Calendar
    // these are the two component with higher precedence than `month`
    let era: Int
    let year: Int
    
    let height: CGFloat
    
    private var months: [Month] {
        let monthIntervals: [DateInterval] = (0...)
            .lazy
            .compactMap { month in
                let dateComponents = DateComponents(era: era, year: year, month: month)
                return calendar.date(from: dateComponents)
            }
            .drop { calendar.component(.year, from: $0) != year }
            .prefix { calendar.component(.year, from: $0) == year }
            .compactMap { calendar.dateInterval(of: .month, for: $0) }
        
        let shortStandaloneMonthSymbols = calendar.shortStandaloneMonthSymbols
        return zip(shortStandaloneMonthSymbols, monthIntervals)
            .map { shortStandaloneSymbol, dateInterval in
                Month(shortStandaloneSymbol: shortStandaloneSymbol, dateInterval: dateInterval)
            }
    }
    
    var body: some View {
        let months = months
        if let firstMonth = months.first, let lastMonth = months.last {
            let yearDuration = lastMonth.dateInterval.end.timeIntervalSince(firstMonth.dateInterval.start)
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(months) { month in
                    Text(month.shortStandaloneSymbol)
                        .font(.callout.monospaced().smallCaps())
                        .foregroundColor(.accentColor)
                        .frame(height: month.dateInterval.duration / yearDuration * height, alignment: .top)
                }
            }
        }
    }
}

private struct Month: Hashable {
    let shortStandaloneSymbol: String
    let dateInterval: DateInterval
}

extension Month: Identifiable {
    var id: Self { self }
}

extension RealTimeRateLimit: ObservableObject {
    
}

extension View {
    func onDragGesture(minimumDistance: CGFloat = 10, coordinateSpace: CoordinateSpace = .local, onChanged action: @escaping (DragGesture.Value) -> Void) -> some View {
        let dragGesture = DragGesture(minimumDistance: minimumDistance, coordinateSpace: coordinateSpace)
            .onChanged(action)
        return gesture(dragGesture)
    }
}
