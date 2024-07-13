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
    
    public init() {
        
    }
    
    // this is called from both the iOS app and the iOS widget (currently).
    // this is to maximize the amount of access we have to location and execution time.
    // for example, the widget may be given location permission and the app only has "while running"
    //   permissions. the widget may be woken up and given processing time. we use this time to
    //   reload the widget if needed.
    // in another example, the widget may not have location permission and the app still has "while running"
    //   permissions. in this case, the app can reload the widget if needed while the app is open.
    public func startMonitoring(locationManager: LocationManager = .shared) {
        guard cancellables.isEmpty else { return }
        // location manager already has logic to minimize the amount that `stapledLocation` changes
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
                        
                        // use the same check that location manager uses
                        if let lastReloadLocation,
                           stapledLocation.location.timestamp.timeIntervalSince(lastReloadLocation.location.timestamp) <= 0 {
                            logger.notice("Skipping stapledLocation update because it matches last reload")
                            return
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
