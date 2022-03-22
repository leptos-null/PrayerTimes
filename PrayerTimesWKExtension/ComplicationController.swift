//
//  ComplicationController.swift
//  PrayerTimesWatch WatchKit Extension
//
//  Created by Leptos on 3/18/22.
//

import ClockKit
import Combine
import CoreLocation
import PrayerTimesKit
import os

class ComplicationController: NSObject, CLKComplicationDataSource {
    private static let logger = Logger(subsystem: "null.leptos.prayertimes.watchkitapp.watchkitextension", category: "ComplicationController")
    
    let locationManager: LocationManager = .shared
    let preferences: Preferences = .shared
    
    enum TemplateGenerationError: Error {
        case unknownComplicationIdentifier(String)
        case unknownComplicationFamily(CLKComplicationFamily)
        case unsupportedConfiguration(CLKComplicationFamily, ComplicationVariation)
    }
    
    private var activeCalculationParameters: CalculationParameters? {
        didSet {
            invalidateActiveComplications()
        }
    }
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    override init() {
        super.init()
        
        let currentTimeZoneSubject: CurrentValueSubject<TimeZone, Never> = .init(.current)
        
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { _ in
                currentTimeZoneSubject.send(.current)
            }
            .store(in: &cancellables)
        
        let locationPublisher = locationManager.$location
            .compactMap { $0 }
        
        currentTimeZoneSubject
            .combineLatest(locationPublisher, preferences.$calculationMethod) { timeZone, location, calculationMethod in
                CalculationParameters(
                    timeZone: timeZone,
                    location: location,
                    configuration: calculationMethod.calculationConfiguration
                )
            }
            .removeDuplicates { (current: CalculationParameters, proposed: CalculationParameters) in
                // this is not really how remove duplicates is meant to be used, but it seems to work
                // the same `current` value will be sent into this closure for as long as this closure returns true
                let now: Date = .now
                let oldModel = DailyPrayers(day: now, calculationParameters: current)
                let newModel = DailyPrayers(day: now, calculationParameters: proposed)
                let dhuhrDifference = oldModel.dhuhr.start.timeIntervalSince(newModel.dhuhr.start).magnitude
                // heuristic used to only update calculation parameters (and therefore invalidate complications)
                //   if there's been a "significant change" in the results
                return (dhuhrDifference < 30)
            }
            .map { $0 } // implicitly convert to Optional
            .assign(to: \.activeCalculationParameters, on: self)
            .store(in: &cancellables)
        
        preferences.$visiblePrayers
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.invalidateActiveComplications()
            }
            .store(in: &cancellables)
    }
    
    private func invalidateActiveComplications() {
        Self.logger.debug(#function)
        let complicationServer: CLKComplicationServer = .sharedInstance()
        complicationServer.activeComplications?
            .forEach(complicationServer.reloadTimeline(for:))
    }
    
    private func timelineEntryFor(prayerPair: (current: Prayer, next: Prayer), complication: CLKComplication) throws -> CLKComplicationTimelineEntry {
        let template = try templateFor(prayerPair: prayerPair, complication: complication)
        return CLKComplicationTimelineEntry(date: prayerPair.current.start, complicationTemplate: template)
    }
    private func templateFor(prayerPair: (current: Prayer, next: Prayer), complication: CLKComplication, timeZone: TimeZone? = nil, relativeTo relativeDate: Date? = nil) throws -> CLKComplicationTemplate {
        let complicationIdentifier = complication.identifier
        guard let variation = ComplicationVariation(id: complicationIdentifier) else {
            throw TemplateGenerationError.unknownComplicationIdentifier(complicationIdentifier)
        }
        let startTime = prayerPair.next.start
        let nameProvider = CLKSimpleTextProvider(text: prayerPair.next.name.localized, shortText: "Next")
        let timeProvider = CLKTimeTextProvider(date: startTime, timeZone: timeZone)
        let countdownProvider = CLKRelativeDateTextProvider(date: startTime, relativeTo: relativeDate, style: .natural, units: [ .hour, .minute, .second ])
        
        let complicationFamily = complication.family
        
        switch variation {
        case .`default`:
            switch complicationFamily {
            case .modularSmall:
                return CLKComplicationTemplateModularSmallStackText(
                    line1TextProvider: nameProvider,
                    line2TextProvider: timeProvider
                )
            case .modularLarge:
                return CLKComplicationTemplateModularLargeStandardBody(
                    headerTextProvider: nameProvider,
                    body1TextProvider: timeProvider,
                    body2TextProvider: countdownProvider
                )
            case .utilitarianSmall, .utilitarianSmallFlat:
                return CLKComplicationTemplateUtilitarianSmallFlat(
                    textProvider: timeProvider
                )
            case .utilitarianLarge:
                return CLKComplicationTemplateUtilitarianLargeFlat(
                    textProvider: CLKTextProvider(format: "%@  %@", nameProvider, timeProvider)
                )
            case .circularSmall:
                return CLKComplicationTemplateCircularSmallStackText(
                    line1TextProvider: nameProvider,
                    line2TextProvider: timeProvider
                )
            case .extraLarge:
                return CLKComplicationTemplateExtraLargeStackText(
                    line1TextProvider: nameProvider,
                    line2TextProvider: timeProvider
                )
            case .graphicCorner:
                return CLKComplicationTemplateGraphicCornerStackText(
                    innerTextProvider: nameProvider,
                    outerTextProvider: timeProvider
                )
            case .graphicBezel:
                throw TemplateGenerationError.unsupportedConfiguration(complicationFamily, variation)
            case .graphicCircular:
                return CLKComplicationTemplateGraphicCircularStackText(
                    line1TextProvider: nameProvider,
                    line2TextProvider: timeProvider
                )
            case .graphicRectangular:
                return CLKComplicationTemplateGraphicRectangularStandardBody(
                    headerTextProvider: nameProvider,
                    body1TextProvider: timeProvider,
                    body2TextProvider: countdownProvider
                )
            case .graphicExtraLarge:
                return CLKComplicationTemplateGraphicExtraLargeCircularStackText(
                    line1TextProvider: nameProvider,
                    line2TextProvider: timeProvider
                )
            @unknown default:
                throw TemplateGenerationError.unknownComplicationFamily(complicationFamily)
            }
        case .extended:
            switch complicationFamily {
            case .utilitarianLarge:
                return CLKComplicationTemplateUtilitarianLargeFlat(
                    textProvider: CLKTextProvider(format: "%@ · %@ · %@", countdownProvider, nameProvider, timeProvider)
                )
            case .modularSmall, .modularLarge, .utilitarianSmall, .utilitarianSmallFlat, .circularSmall, .extraLarge,
                    .graphicCorner, .graphicBezel, .graphicCircular, .graphicRectangular, .graphicExtraLarge:
                throw TemplateGenerationError.unsupportedConfiguration(complicationFamily, variation)
            @unknown default:
                throw TemplateGenerationError.unknownComplicationFamily(complicationFamily)
            }
        }
    }
    
    // MARK: - Complication Configuration
    
    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        let descriptors = [
            CLKComplicationDescriptor(identifier: ComplicationVariation.default.id, displayName: "Prayer Times", supportedFamilies: [
                .modularSmall,
                .modularLarge,
                .utilitarianSmall,
                .utilitarianSmallFlat,
                .utilitarianLarge,
                .circularSmall,
                .extraLarge,
                .graphicCorner,
                .graphicCircular,
                .graphicRectangular,
                .graphicExtraLarge
            ]),
            CLKComplicationDescriptor(identifier: ComplicationVariation.extended.id, displayName: "Prayer Times (Extended)", supportedFamilies: [
                .utilitarianLarge,
            ])
        ]
        return descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func timelineEndDate(for complication: CLKComplication) async -> Date? {
        return .distantFuture
    }
    
    func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {
        return .showOnLockScreen
    }
    
    // MARK: - Timeline Population
    
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        guard let calculationParameters = activeCalculationParameters else { return nil }
        
        var prayerIterator = PrayerIterator(start: .now, calculationParameters: calculationParameters, filter: preferences.visiblePrayers)
        let first = prayerIterator.next()!
        let second = prayerIterator.next()!
        do {
            let timelineEntry = try timelineEntryFor(prayerPair: (current: first, next: second), complication: complication)
            return timelineEntry
        } catch {
            Self.logger.error("timelineEntryFor(complication: \(complication)): \(String(describing: error))")
            return nil
        }
    }
    
    func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry]? {
        guard let calculationParameters = activeCalculationParameters else { return nil }
        
        let startTimes = PrayerIterator(start: date, calculationParameters: calculationParameters, filter: preferences.visiblePrayers)
        
        let endTimes = startTimes
            .prefix(limit + 1)
            .dropFirst()
        
        return zip(startTimes, endTimes)
            .compactMap { prayerPair in
                do {
                    let timelineEntry = try timelineEntryFor(prayerPair: prayerPair, complication: complication)
                    return timelineEntry
                } catch {
                    Self.logger.error("timelineEntryFor(complication: \(complication)): \(String(describing: error))")
                    return nil
                }
            }
    }
    
    // MARK: - Sample Templates
    
    private static var sampleTemplateTimeZone = TimeZone(identifier: "America/Los_Angeles")!
    
    private static var sampleTemplatePrayerPair: (Prayer, Prayer) = {
        // Apple Park
        let calculationParameters = CalculationParameters(
            timeZone: sampleTemplateTimeZone,
            location: CLLocation(latitude: 37.334900, longitude: -122.009020),
            configuration: CalculationMethod.isna.calculationConfiguration
        )
        // intentionally not passing a filter here, since we don't want to read user preferences
        //   (for the sake of the sample template being consistent)
        var prayerIterator = PrayerIterator(start: sampleTemplateRelativeDate, calculationParameters: calculationParameters)
        let first = prayerIterator.next()!
        let second = prayerIterator.next()!
        return (first, second)
    }()
    
    private static var sampleTemplateRelativeDate: Date = {
        let timeZone = sampleTemplateTimeZone
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        // Watch preview date
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone)
        dateComponents.year = 2014
        dateComponents.month = 9
        dateComponents.day = 9
        dateComponents.hour = 10
        dateComponents.minute = 9
        dateComponents.second = 30
        
        return dateComponents.date!
    }()
    
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        do {
            let timelineEntry = try templateFor(
                prayerPair: Self.sampleTemplatePrayerPair,
                complication: complication,
                timeZone: Self.sampleTemplateTimeZone,
                relativeTo: Self.sampleTemplateRelativeDate
            )
            return timelineEntry
        } catch {
            Self.logger.error("timelineEntryFor(complication: \(complication)): \(String(describing: error))")
            return nil
        }
    }
}

enum ComplicationVariation: Hashable, CaseIterable {
    case `default`
    case extended
}

extension ComplicationVariation: Identifiable {
    init?(id: String) {
        guard let match = Self.allCases.first(where: { $0.id == id }) else { return nil }
        self = match
    }
    
    var id: String {
        switch self {
        case .`default`:
            return CLKDefaultComplicationIdentifier
        case .extended:
            return "PTExtendedComplicationIdentifier"
        }
    }
}
