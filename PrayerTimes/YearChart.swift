//
//  YearChart.swift
//  PrayerTimes
//
//  Created by Leptos on 7/19/24.
//

import SwiftUI
import Charts
import PrayerTimesKit
import PrayerTimesUI

@available(iOS 16.0, *)
struct YearChart: View {
    let data: YearChartData
    let locationTitle: String
    
    @GestureState private var gestureLollipop: Date?
    @State private var hoverLollipop: Date?
    
    private static let secondsPerHour: TimeInterval = 60 /* seconds per minute */ * 60 /* minutes per hour */
    private static let secondsPerDay: TimeInterval = secondsPerHour * 24 /* hours per day */
    
    private static func yAxisFormatter(calendar: Calendar) -> Date.FormatStyle {
        let zeroTimeZone = TimeZone(secondsFromGMT: 0)!
        
        var calendarCopy = calendar
        calendarCopy.timeZone = zeroTimeZone
        
        return Date.FormatStyle(
            date: .omitted, time: .shortened,
            calendar: calendarCopy, timeZone: zeroTimeZone,
            capitalizationContext: .listItem
        )
    }
    
    private static func color(for prayerName: Prayer.Name) -> Color {
        switch prayerName {
        case .qiyam: .purple
        case .fajr: .indigo
        case .sunrise: .red
        case .dhuhr: .yellow
        case .asr: .teal
        case .maghrib: .orange
        case .isha: .blue
        }
    }
    
    private var calendar: Calendar {
        data.statistics.calendar
    }
    
    private var lollipop: Date? {
        gestureLollipop ?? hoverLollipop
    }
    
    private func dateForInteraction(at point: CGPoint, chartProxy: ChartProxy, geometryProxy: GeometryProxy, allowOutOfBounds: Bool) -> Date? {
        let space = geometryProxy[chartProxy.plotAreaFrame]
        let xCoordinate = point.x - space.origin.x
        let bounds = 0..<space.width
        guard allowOutOfBounds || bounds.contains(xCoordinate) else {
            return nil
        }
        let xClamped = max(bounds.lowerBound, min(xCoordinate, bounds.upperBound))
        guard let date: Date = chartProxy.value(atX: xClamped) else {
            return nil
        }
        let days = data.statistics.daysPrayers
        guard let first = days.first,
              let last = days.last else {
            assertionFailure("data.statistics.daysPrayers has no items")
            return nil
        }
        // create a more strict interval than `data.statistics.dateInterval`
        // to avoid picking a date very close to the next year,
        // which would sometimes cause the graph to adjust to show
        // the first day of the next year
        return max(first.dhuhr.start, min(date, last.dhuhr.start))
    }
    
    @ViewBuilder
    private var horizontalLegend: some View {
        HStack(alignment: .top, spacing: 0) {
            let dailyPrayers = DailyPrayers(day: lollipop ?? data.statistics.dateInterval.start, calculationParameters: data.statistics.calculationParameters)
            ForEach(Prayer.Name.allCases) { prayerName in
                if data.seriesMap.keys.contains(prayerName) {
                    HStack(alignment: .top) {
                        Circle()
                            .fill(Self.color(for: prayerName))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text(prayerName.localized)
                            Text(dailyPrayers.prayer(named: prayerName).start, style: .time)
                                .opacity(lollipop != nil ? 1 : 0)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var verticalLegend: some View {
        HStack {
            VStack(alignment: .leading) {
                ForEach(Prayer.Name.allCases) { prayerName in
                    if data.seriesMap.keys.contains(prayerName) {
                        HStack(alignment: .center) {
                            Circle()
                                .fill(Self.color(for: prayerName))
                                .frame(width: 12, height: 12)
                            
                            Text(prayerName.localized)
                        }
                    }
                }
            }
            if let lollipop {
                VStack(alignment: .leading) {
                    let dailyPrayers = DailyPrayers(day: lollipop, calculationParameters: data.statistics.calculationParameters)
                    ForEach(Prayer.Name.allCases) { prayerName in
                        if data.seriesMap.keys.contains(prayerName) {
                            HStack(alignment: .center) {
                                Circle()
                                    .fill(.clear)
                                    .frame(width: 0, height: 12)
                                
                                Text(dailyPrayers.prayer(named: prayerName).start, style: .time)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
    }
    
    private var yearFormatter: Date.FormatStyle {
        Date.FormatStyle(
            calendar: data.statistics.calendar, timeZone: data.statistics.calculationParameters.timeZone,
            capitalizationContext: .middleOfSentence
        )
        .year(.extended())
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Prayer times over \(data.statistics.dateInterval.start, format: yearFormatter)")
                        .font(.headline)
                    Text(locationTitle)
                        .font(.subheadline)
                        .padding(.bottom, 8)
                    
                    Text(lollipop ?? .now, style: .date)
                        .font(.callout)
                        .opacity(lollipop != nil ? 1 : 0)
                }
                Spacer()
            }
            .padding()
            
            Chart(Prayer.Name.allCases) { (prayerName: Prayer.Name) in
                if let pairs = data.seriesMap[prayerName] {
                    ForEach(pairs) { pair in
                        LineMark(
                            x: .value("Day", pair.date, unit: .day),
                            y: .value("Time", pair.offset)
                        )
                    }
                    .foregroundStyle(by: .value("Prayer", prayerName))
                    .interpolationMethod(.catmullRom)
                }
                
                if let lollipop {
                    // ideally I would like to use a hierarchical style,
                    // but the foregroundStyle for the chart is already
                    // set to the tint color for some reason.
                    // The tint color is blue, which is one of the line colors as well.
                    // Use gray to more closely match the label colors in the legend.
                    RuleMark(x: .value("Day", lollipop, unit: .day))
                        .foregroundStyle(.gray)
                }
            }
            .aspectRatio(1.5, contentMode: .fit)
            .chartYScale(domain: 0...Self.secondsPerDay)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, calendar: calendar))
            }
            .chartYAxis {
                AxisMarks(
                    format: Self.yAxisFormatter(calendar: calendar),
                    values: .stride(by: 4 * Self.secondsPerHour, roundUpperBound: false)
                )
            }
            .chartForegroundStyleScale { (prayerName: Prayer.Name) in
                Self.color(for: prayerName)
            }
            .chartLegend(.hidden) // we provide our own legend
            .chartOverlay { chartProxy in
                GeometryReader { geometryProxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($gestureLollipop) { dragValue, lollipop, transaction in
                                    lollipop = dateForInteraction(
                                        at: dragValue.location,
                                        chartProxy: chartProxy, geometryProxy: geometryProxy,
                                        allowOutOfBounds: true
                                    )
                                }
                        )
                        .onContinuousHover { phase in
                            // thanks to help from https://nilcoalescing.com/blog/TrackingHoverLocationInSwiftUI/
                            switch phase {
                            case .active(let point):
                                hoverLollipop = dateForInteraction(
                                    at: point,
                                    chartProxy: chartProxy, geometryProxy: geometryProxy,
                                    allowOutOfBounds: false
                                )
                            case .ended:
                                hoverLollipop = nil
                            }
                        }
                }
            }
            
            ViewThatFits(in: .horizontal) {
                horizontalLegend
                verticalLegend
            }
            .foregroundStyle(.secondary)
            .font(.caption)
            .padding(.top)
            
            Spacer(minLength: 0)
        }
        .environment(\.timeZone, data.statistics.calculationParameters.timeZone)
        .scenePadding()
    }
}

@available(iOS 16.0, *)
extension Prayer.Name: Plottable {
    // these are category names, so they should be localized
    public var primitivePlottable: String {
        localized
    }
    
    public init?(primitivePlottable: String) {
        let match = Self.allCases.first { $0.localized == primitivePlottable }
        guard let match else { return nil }
        self = match
    }
}
