//
//  SystemRegistrar.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/25/22.
//

import Foundation
import CoreLocation
import Combine
import os

public final class SystemRegistrar {
    private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "SystemRegistrar")
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    public init() {
        
    }
    
    public func startRegistering(locationManager: LocationManager = .shared, preferences: Preferences = .shared) {
        guard cancellables.isEmpty else { return }
#if os(iOS) || os(macOS)
        locationManager.$authorizationStatus
            .sink { authorizationStatus in
                guard authorizationStatus == .authorizedAlways else { return }
                locationManager.startMonitoringSignificantLocationChanges()
            }
            .store(in: &cancellables)
#endif
        
#if os(iOS) || os(macOS) || os(watchOS)
        // only if we have a reason to request always authorization, should we
        preferences.$userNotifications
            .sink { userNotificationPreferences in
                guard !userNotificationPreferences.isEmpty else { return }
                locationManager.requestAlwaysAuthorization()
            }
            .store(in: &cancellables)
        
        locationManager.$placemark
            .combineLatest(preferences.$calculationConfiguration, preferences.$userNotifications) { ($0, $1, $2) }
            .sink { (placemark, configuration, userNotificationPreferences) in
                guard let location = placemark?.location ?? locationManager.location else {
                    Self.logger.error("No usable location while registering for user notifications")
                    return
                }
                
                let locationText: String
                if let placemarkTitle = locationManager.placemark?.locationTitle {
                    locationText = "in \(placemarkTitle)"
                } else {
                    locationText = "near \(location.coordinateText)"
                }
                
                let calculationParameters = CalculationParameters(
                    timeZone: placemark?.timeZone ?? .current,
                    location: location,
                    configuration: configuration
                )
                Task {
                    try await UserNotification.registerFor(calculationParameters: calculationParameters, preferences: userNotificationPreferences, bodyText: locationText)
                }
            }
            .store(in: &cancellables)
#endif
    }
    
    public func stopRegistering() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
