//
//  DailyPrayersView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 1/26/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit

struct DailyPrayersView<Header: View>: View {
    let dailyPrayers: DailyPrayers
    let orderedPrayers: [Prayer]
    private let current: Prayer?
    private let headerBuilder: (Date) -> Header
    
    // for everything to line up, each VStack involved must have the same spacing
    private let verticalSpacing: CGFloat = 8
    
    init(dailyPrayers: DailyPrayers, time: Date? = nil, visiblePrayers: Set<Prayer.Name>, @ViewBuilder header: @escaping (Date) -> Header) {
        let filteredPrayers = dailyPrayers.ordered.filter(visiblePrayers)
        self.dailyPrayers = dailyPrayers
        self.orderedPrayers = filteredPrayers
        self.headerBuilder = header
        
        if let time = time {
            current = filteredPrayers.activePrayer(for: time)
        } else {
            current = nil
        }
    }
    
    var body: some View {
        VStack {
            headerBuilder(dailyPrayers.dhuhr.start)
            
            Spacer()
                .frame(height: 4)
            
            DateSubtitle(date: dailyPrayers.dhuhr.start)
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: verticalSpacing) {
                    ForEach(orderedPrayers) { prayer in
                        viewFor(prayer: prayer, mode: .title)
                    }
                }
                
                Spacer()
                    .frame(minWidth: 4, maxWidth: 84)
                
                VStack(alignment: .trailing, spacing: verticalSpacing) {
                    ForEach(orderedPrayers) { prayer in
                        viewFor(prayer: prayer, mode: .detail)
                    }
                }
            }
            .accessibilityRepresentation {
                VStack(spacing: verticalSpacing) {
                    ForEach(orderedPrayers) { prayer in
                        HStack(spacing: 0) {
                            viewFor(prayer: prayer, mode: .title)
                            Spacer()
                            viewFor(prayer: prayer, mode: .detail)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(textFor(prayer: prayer, mode: .title))
                        .accessibilityValue(textFor(prayer: prayer, mode: .detail))
                    }
                }
            }
        }
        .environment(\.timeZone, dailyPrayers.calculationParameters.timeZone)
    }
}

extension DailyPrayersView {
    enum TitleDetailMode {
        case title
        case detail
    }
    
    private func textFor(prayer: Prayer, mode: TitleDetailMode) -> Text {
        switch mode {
        case .title:
            return Text(prayer.name.localized)
        case .detail:
            return Text(prayer.start, style: .time)
        }
    }
    
    private func viewFor(prayer: Prayer, mode: TitleDetailMode) -> some View {
        textFor(prayer: prayer, mode: mode)
            .fontWeight((prayer == current) ? .semibold : .regular)
            .padding(.vertical, 6)
    }
}

extension Prayer: Identifiable {
    public var id: Prayer { self }
}

struct DailyPrayersView_Previews: PreviewProvider {
    static var previews: some View {
        DailyPrayersView(dailyPrayers: DailyPrayers(
            day: Date(timeIntervalSinceReferenceDate: 664581600),
            calculationParameters: CalculationParameters(
                timeZone: TimeZone(identifier: "Africa/Johannesburg")!,
                location: CLLocation(latitude: -29.856687, longitude: 31.017086),
                configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
            )
        ), visiblePrayers: Set(Prayer.Name.allCases), header: DateTitle.init(date:))
    }
}
