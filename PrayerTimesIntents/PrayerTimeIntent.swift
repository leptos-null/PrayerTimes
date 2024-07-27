//
//  PrayerTimeIntent.swift
//  PrayerTimesIntents
//
//  Created by Leptos on 6/16/24.
//

import AppIntents
import PrayerTimesKit
import CoreLocation

enum AppIntentPerformError: Int, Error, CustomNSError {
    case noLocation
    
    static var errorDomain: String { "null.leptos.prayertimes.appintents" }
    
    var errorCode: Int { rawValue }
}

struct PrayerTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Prayer Time"
    
    static let description: IntentDescription? = IntentDescription("The time of a prayer on a given day and location")
    
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @Parameter(title: "Prayer")
    var targetPrayer: PrayerNameIntentValue
    
    @Parameter(title: "Date")
    var date: Date?
    
    @Parameter(title: "Location")
    var placemark: CLPlacemark?
    
    func perform() async throws -> some ReturnsValue<Date> & ProvidesDialog {
        let preferences: Preferences = .shared
        
        let location: CLLocation?
        let timeZone: TimeZone?
        
        if let placemark {
            location = placemark.location
            timeZone = placemark.timeZone
        } else if let stored = LocationManager.shared.stapledLocation {
            location = stored.location
            timeZone = stored.placemark?.timeZone
        } else if let stored = LocationManager.shared.location {
            location = stored
            timeZone = nil
        } else {
            throw $placemark.needsValueError()
        }
        
        guard let location else {
            throw AppIntentPerformError.noLocation
        }
        
        let parameters = CalculationParameters(
            timeZone: timeZone ?? .current,
            location: location,
            configuration: preferences.calculationMethod.calculationConfiguration
        )
        
        let targetDate = date ?? systemContext.preciseTimestamp ?? .now
        let ptName = Prayer.Name(intentValue: targetPrayer)
        
        let day = DailyPrayers(day: targetDate, calculationParameters: parameters)
        let prayer = day.prayer(named: ptName)
        
        let timeFormat = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: parameters.timeZone, capitalizationContext: .unknown)
        // providing a "dialog" value has 2 purposes:
        // 1. this seems to be required to "respond" to a Siri request for one of the AppShortcut phrases
        // 2. for similar reasons as the previous point, if the user creates a Shortcut with only this action,
        //      the Shortcut will appear to do nothing; the value will be provided, but the user has to be in the
        //      Shortcut workflow editor to see that value
        return .result(value: prayer.start, dialog: IntentDialog("\(prayer.start, format: timeFormat)"))
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get time for \(\.$targetPrayer) on \(\.$date) in \(\.$placemark)")
    }
}
