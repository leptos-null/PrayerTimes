//
//  UpNextWidget.swift
//  PrayerTimesWidget
//
//  Created by Leptos on 7/8/24.
//

import WidgetKit
import SwiftUI
import PrayerTimesKit
import CoreLocation

private struct Provider: TimelineProvider {
    typealias Entry = PrayerEntry
    
    func placeholder(in context: Context) -> Entry {
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        // Apple Park
        let calculationParameters = CalculationParameters(
            timeZone: timeZone,
            location: CLLocation(latitude: 37.334900, longitude: -122.009020),
            configuration: CalculationMethod.isna.calculationConfiguration
        )
        
        let iterator = PrayerIterator(start: .now, calculationParameters: calculationParameters)
        let entry = PrayerEntry(prayerIterator: iterator, stapledLocation: nil)
        return entry!
    }
    
    private func getUserParameters() -> (calculationParameters: CalculationParameters?, stapledLocation: StapledLocation?, visiblePrayers: Set<Prayer.Name>) {
        let preferences: Preferences = .shared
        let locationManager: LocationManager = .shared
        
        let visiblePrayers = preferences.visiblePrayers
        guard let stapledLocation = locationManager.stapledLocation else {
            return (nil, nil, visiblePrayers)
        }
        
        let calculationParameters = CalculationParameters(
            timeZone: stapledLocation.placemark?.timeZone ?? .current,
            location: stapledLocation.location,
            configuration: preferences.calculationMethod.calculationConfiguration
        )
        return (calculationParameters, stapledLocation, visiblePrayers)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let (calculationParameters, stapledLocation, visiblePrayers) = getUserParameters()
        guard let calculationParameters, let stapledLocation else {
            let entry = PrayerEntry(date: .now, prayerIterator: nil, stapledLocation: nil)
            completion(entry)
            return
        }
        
        let iterator = PrayerIterator(start: .now, calculationParameters: calculationParameters, filter: visiblePrayers)
        let entry = PrayerEntry(prayerIterator: iterator, stapledLocation: stapledLocation)
        completion(entry!)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let (calculationParameters, stapledLocation, visiblePrayers) = getUserParameters()
        guard let calculationParameters, let stapledLocation else {
            let entry = PrayerEntry(date: .now, prayerIterator: nil, stapledLocation: nil)
            completion(Timeline(entries: [entry], policy: .never))
            return
        }
        
        var iterator = PrayerIterator(start: .now, calculationParameters: calculationParameters, filter: visiblePrayers)
        
        let maxEntries = 64 // arbitrary
        let entries: [PrayerEntry] = (1...maxEntries).compactMap { _ in
            let copy = iterator
            guard let peek = iterator.next() else { return nil }
            return PrayerEntry(date: peek.start, prayerIterator: copy, stapledLocation: stapledLocation)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct PrayerEntry: TimelineEntry {
    let date: Date
    
    let prayerIterator: PrayerIterator? // nil if no location data
    let stapledLocation: StapledLocation? // nil for placeholder
    
    init(date: Date, prayerIterator: PrayerIterator?, stapledLocation: StapledLocation?) {
        self.date = date
        self.prayerIterator = prayerIterator
        self.stapledLocation = stapledLocation
    }
    
    init?(prayerIterator: PrayerIterator, stapledLocation: StapledLocation?) {
        var copy = prayerIterator
        guard let nowPrayer = copy.next() else { return nil }
        self.init(date: nowPrayer.start, prayerIterator: prayerIterator, stapledLocation: stapledLocation)
    }
}

private struct EntryView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    private var locationText: String {
        guard let stapledLocation = entry.stapledLocation else {
            return "Placeholder"
        }
        return stapledLocation.placemark?.locationTitle ?? stapledLocation.location.coordinateText
    }
    
    private func upNext(prayerIterator: PrayerIterator) -> [Prayer] {
        let size = switch widgetFamily {
        case .systemSmall: 1
        case .systemMedium: 3
        case .systemLarge: 5
        default: 1
        }
        return Array(prayerIterator.dropFirst(1).prefix(size))
    }
    
    private func next(prayerIterator: PrayerIterator) -> Prayer? {
        var copy = prayerIterator
        _ = copy.next() // drop
        return copy.next()
    }

    var body: some View {
        Group {
            if let prayerIterator = entry.prayerIterator {
                VStack {
                    Text(locationText)

                    switch widgetFamily {
                    case .systemSmall:
                        if let prayer = next(prayerIterator: prayerIterator) {
                            VStack(alignment: .leading) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("next:")
                                        .foregroundStyle(.secondary)
                                    Text(prayer.name.localized)
                                        .bold()
                                }
                                HStack(alignment: .firstTextBaseline) {
                                    Text("at")
                                        .foregroundStyle(.secondary)
                                    Text(prayer.start, style: .time)
                                        .bold()
                                }
                                HStack(alignment: .firstTextBaseline) {
                                    Text("in")
                                        .foregroundStyle(.secondary)
                                    Text(prayer.start, style: .relative)
                                }
                            }
                            .padding(.top, 2)
                        }
                    default:
                        ForEach(upNext(prayerIterator: prayerIterator), id: \.start) { prayer in
                            Spacer()
                            HStack {
                                Text(prayer.name.localized)
                                    .bold()
                                Text("at")
                                    .foregroundStyle(.secondary)
                                Text(prayer.start, style: .time)
                                    .bold()
                                Text("in")
                                    .foregroundStyle(.secondary)
                                Text(prayer.start, style: .relative)
                            }
                        }
                    }
                }
                .environment(\.timeZone, prayerIterator.calculationParameters.timeZone)
            } else {
                VStack {
                    switch widgetFamily {
                    case .systemSmall:
                        Text("No location configured")
                            .font(.headline)
                            .padding()
                        Text("Tap to configure in the app")
                            .font(.callout)
                    default:
                        Text("No location configured")
                            .font(.headline)
                            .padding()
                        Text("Please tap to configure location in the app")
                            .font(.callout)
                    }
                }
            }
        }
    }
}

private extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0, *) {
            return self
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            return self
        }
    }
}

struct UpNextWidget: Widget {
    static let kind: String = "UpNextWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
            EntryView(entry: entry)
                .widgetBackground()
        }
        .configurationDisplayName("Up Next")
        .containerBackgroundRemovable()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UpNextWidget_Previews: PreviewProvider {
    private static let placeholderEntry: PrayerEntry = {
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        // Apple Park
        let calculationParameters = CalculationParameters(
            timeZone: timeZone,
            location: CLLocation(latitude: 37.334900, longitude: -122.009020),
            configuration: CalculationMethod.isna.calculationConfiguration
        )
        
        let iterator = PrayerIterator(start: .now, calculationParameters: calculationParameters)
        let entry = PrayerEntry(prayerIterator: iterator, stapledLocation: nil)
        return entry!
    }()

    static var previews: some View {
        EntryView(entry: .init(date: .now, prayerIterator: nil, stapledLocation: nil))
            .widgetBackground()
            .previewContext(WidgetPreviewContext(family: .systemMedium))

        EntryView(entry: placeholderEntry)
            .widgetBackground()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}