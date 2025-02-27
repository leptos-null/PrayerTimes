//
//  TimesView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/18/22.
//

import SwiftUI
import PrayerTimesKit

struct TimesView: View {
    let calculationParameters: CalculationParameters
    let locationTitle: String
    
    @Environment(\.visiblePrayers) private var visiblePrayers
    
    var body: some View {
        NavigationView {
            ScrollView {
                TimelineView(.prayers(with: calculationParameters, visiblePrayers: visiblePrayers)) { timelineContext in
                    VStack(alignment: .leading, spacing: 4) {
                        // this label is effectively static and doesn't need to be in the TimelineView
                        //   but including it inside the TimelineView simplifies layout
                        Text(locationTitle)
                            .font(.headline)
                        RollingPrayersView(startDate: timelineContext.date, calculationParameters: calculationParameters, visiblePrayers: visiblePrayers)
                            .environment(\.timeZone, calculationParameters.timeZone)
                    }
                }
            }
        }
    }
}

struct KeyValuePair<Key, Value> {
    var key: Key
    var value: Value
}

extension KeyValuePair: Equatable where Key: Equatable, Value: Equatable {
    
}

extension KeyValuePair: Hashable where Key: Hashable, Value: Hashable {
    
}

extension KeyValuePair: Identifiable where Key: Hashable {
    var id: Key { key }
}

struct RollingPrayersView: View {
    private static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    let groupedPrayers: [KeyValuePair<Date, [Prayer]>]
    
    private let currentPrayer: Prayer?
    private let nextPrayer: Prayer?
    
    init(startDate: Date, calculationParameters: CalculationParameters, visiblePrayers: Set<Prayer.Name>) {
        let maxPrayers = visiblePrayers.count
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calculationParameters.timeZone
        
        let prayerSequence = PrayerIterator(start: startDate, calculationParameters: calculationParameters, filter: visiblePrayers)
        
        var prayerIterator = prayerSequence
        currentPrayer = prayerIterator.next()
        nextPrayer = prayerIterator.next()
        
        groupedPrayers = prayerSequence
            .prefix(maxPrayers)
            .reduce(into: []) { partialResult, prayer in
                let key: Date = calendar.startOfDay(for: prayer.start)
                // the input is in order, so either we have the same day as the previous prayer or we're on the next day
                if let index = partialResult.indices.last, partialResult[index].key == key {
                    partialResult[index].value.append(prayer)
                } else {
                    partialResult.append(.init(key: key, value: [ prayer ]))
                }
            }
    }
    
    var body: some View {
        if let nextPrayer = nextPrayer {
            Text("\(nextPrayer.name.localized) starts in:")
            Text(nextPrayer.start, style: .timer)
        }
        ForEach(groupedPrayers) { keyValuePair in
            Section {
                PrayerListView(prayers: keyValuePair.value, current: currentPrayer)
            } header: {
                if keyValuePair != groupedPrayers.first {
                    Text(keyValuePair.key, formatter: Self.relativeDateFormatter)
                        .font(.headline)
                }
            }
        }
    }
}

struct PrayerListView: View {
    private struct Row: View {
        let title: Text
        let detail: Text
        
        init(title: () -> Text, detail: () -> Text) {
            self.title = title()
            self.detail = detail()
        }
        
        var body: some View {
            HStack {
                title
                Spacer()
                detail
            }
            .padding()
            .frame(minHeight: 44)
            .background(.quaternary)
            .cornerRadius(8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(detail)
        }
    }
    
    let prayers: [Prayer]
    let current: Prayer?
    
    var body: some View {
        ForEach(prayers) { prayer in
            Row {
                Text(prayer.name.localized)
                    .fontWeight((prayer == current) ? .semibold : .regular)
            } detail: {
                Text(prayer.start, style: .time)
                    .fontWeight((prayer == current) ? .semibold : .regular)
            }
        }
    }
}

extension Prayer: @retroactive Identifiable {
    public var id: Prayer { self }
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
