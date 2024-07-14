//
//  WidgetManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 7/13/24.
//

#if canImport(WidgetKit)
#if os(iOS) // right now only for iOS because we currently only provide widgets on iOS

import WidgetKit
import Combine
import os

public final class WidgetManager {
    private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "WidgetManager")
    
    private let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup")
    private let lastReloadLocationUserDefaultsKey = "WidgetManagerLastReloadLocation"
    
    private var cancellables: Set<AnyCancellable> = []
    
    private static func dhuhrFor(date: Date, stapledLocation: StapledLocation, calculationMethod: CalculationMethod) -> Date {
        let parameters = CalculationParameters(
            timeZone: stapledLocation.placemark?.timeZone ?? .current,
            location: stapledLocation.location,
            configuration: calculationMethod.calculationConfiguration
        )
        let dailyPrayers = DailyPrayers(day: date, calculationParameters: parameters)
        return dailyPrayers.dhuhr.start
    }
    
    public init() {
        
    }
    
    // this is called from both the iOS app and the iOS widget (currently).
    // this is to maximize the amount of access we have to location and execution time.
    // for example, the widget may be given location permission and the app only has "while running"
    //   permissions. the widget may be woken up and given processing time. we use this time to
    //   reload the widget if needed.
    // in another example, the widget may not have location permission and the app still has "while running"
    //   permissions. in this case, the app can reload the widget if needed while the app is open.
    public func startMonitoring(locationManager: LocationManager = .shared, preferences: Preferences = .shared) {
        guard cancellables.isEmpty else { return }
        
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [unowned self] notification in
                guard let userDefaults else {
                    logger.error("userDefaults == nil")
                    return
                }
                let lastReloadLocation: StapledLocation?
                do {
                    lastReloadLocation = try userDefaults.decodedValue(forKey: lastReloadLocationUserDefaultsKey)
                } catch {
                    logger.error("decodedValue(forKey: \(self.lastReloadLocationUserDefaultsKey)): \(error as NSError)")
                    return
                }
                
                if let lastReloadLocation,
                   lastReloadLocation.placemark?.timeZone == nil {
                    // if the last reload location did not have a time zone, then reload
                    logger.notice("reloadAllTimelines (becuase of NSSystemTimeZoneDidChange)")
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .store(in: &cancellables)
        
        preferences.$calculationMethod
            .removeDuplicates()
            .dropFirst() // ignore the event that occurs when we first subscribe
            .sink { [unowned self] calculationMethod in
                // if the calculationMethod changes at all, reload.
                logger.notice("reloadAllTimelines (becuase of calculationMethod change)")
                // run on the next event loop to make sure
                //   the value has been written to user defaults
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .store(in: &cancellables)
        
        preferences.$visiblePrayers
            .removeDuplicates()
            .dropFirst() // ignore the event that occurs when we first subscribe
            .sink { [unowned self] visiblePrayers in
                // if the visiblePrayers changes at all, reload.
                logger.notice("reloadAllTimelines (becuase of visiblePrayers change)")
                // run on the next event loop to make sure
                //   the value has been written to user defaults
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .store(in: &cancellables)
        
        locationManager.$stapledLocation
            .compactMap { $0 }
            .sink { [unowned self] stapledLocation in
                if let userDefaults {
                    do {
                        let lastReloadLocation: StapledLocation? = try userDefaults.decodedValue(forKey: lastReloadLocationUserDefaultsKey)
                        // this aims to check two cases:
                        //   1. if `startMonitoring` was just called, and there's been no
                        //     location change since the last time this pipeline ran.
                        //   2. when stapledLocation changes, and both the app
                        //     and widget try to process the same change.
                        //     there's a chance of a race here; if there is a race,
                        //     it's not that bad, because we just call reload twice.
                        if let lastReloadLocation {
                            let date: Date = .now
                            let last = Self.dhuhrFor(date: date, stapledLocation: lastReloadLocation, calculationMethod: preferences.calculationMethod)
                            let proposed = Self.dhuhrFor(date: date, stapledLocation: stapledLocation, calculationMethod: preferences.calculationMethod)
                            
                            // if dhuhr is less than 30 seconds apart
                            // *and* the location titles are the same
                            //   (ignoring the case where both are nil because then the user doesn't care that much)
                            // then it is safe to skip
                            if last.timeIntervalSince(proposed).magnitude < 30,
                               lastReloadLocation.placemark?.locationTitle == stapledLocation.placemark?.locationTitle {
                                logger.notice("Skipping stapledLocation update because it matches last reload")
                                return
                            }
                        }
                    } catch {
                        logger.error("decodedValue(forKey: \(self.lastReloadLocationUserDefaultsKey)): \(error as NSError)")
                    }
                    
                    do {
                        try userDefaults.setEncoded(value: stapledLocation, forKey: lastReloadLocationUserDefaultsKey)
                    } catch {
                        logger.error("setEncoded(value: \(String(describing: stapledLocation)), forKey: \(self.lastReloadLocationUserDefaultsKey)): \(error as NSError)")
                    }
                } else {
                    logger.error("userDefaults == nil")
                }
                
                logger.notice("reloadAllTimelines (becuase of stapledLocation change)")
                // run on the next event loop to make sure
                //   the didSet on `stapledLocation` has run
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .store(in: &cancellables)
    }
    
    public func stopMonitoring() {
        cancellables.removeAll()
    }
}

#endif /* iOS */
#endif /* WidgetKit */
