//
//  LocationManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/25/22.
//

import Foundation
import CoreLocation
import os

public final class LocationManager: ObservableObject {
    public static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let delegate = Delegate()
    private let observer = KeyValueObserver()
    
    private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "LocationManager")
    
    private let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup")
    private let locationUserDefaultsKey = "LocationManagerLocation"
    private let stapledLocationUserDefaultsKey = "LocationManagerStapledLocation"
    
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    
    @Published public private(set) var location: CLLocation? {
        didSet {
            guard let location = location else {
                logger.log("location set to nil")
                return
            }
            Task(priority: .utility) { [weak self] in
                guard let self = self else { return }
                if let stapledLocation = try await self.stapledLocation(for: location),
                   stapledLocation != self.stapledLocation {
                    DispatchQueue.main.async { [weak self] in
                        self?.stapledLocation = stapledLocation
                    }
                }
            }
            // TODO: avoid writing location to UserDefaults if the value in UserDefaults is the same
            guard let userDefaults = userDefaults else { return }
            logger.debug("archiving: \(location)")
            do {
                try userDefaults.setArchived(object: location, forKey: locationUserDefaultsKey)
            } catch {
                logger.error("setArchived(object: \(location), forKey: \(self.locationUserDefaultsKey)): \(String(describing: error))")
            }
        }
    }
    
    @Published public private(set) var stapledLocation: StapledLocation? {
        didSet {
            guard let stapledLocation = stapledLocation else {
                logger.log("stapledLocation set to nil")
                return
            }
            logger.debug("stapledLocation = \(String(describing: stapledLocation))")
            guard let userDefaults = userDefaults else { return }
            
            // TODO: avoid writing stapledLocation to UserDefaults if the value in UserDefaults is the same
            do {
                try userDefaults.setEncoded(value: stapledLocation, forKey: stapledLocationUserDefaultsKey)
            } catch {
                logger.error("userDefaults.setEncoded(value: \((String(describing: stapledLocation))), forKey: \(self.stapledLocationUserDefaultsKey)): \(String(describing: error))")
            }
        }
    }
    
    private var activeGeocoder: CLGeocoder?
    
    init() {
        locationManager.distanceFilter = 500
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
#if SCREENSHOT_MODE
        authorizationStatus = .authorizedAlways // our desired state is what should show up in screenshots
#else
        authorizationStatus = locationManager.authorizationStatus
#endif
        delegate.locationManager = self
#if !SCREENSHOT_MODE /* don't connect the delegate in screenshot mode- that way we won't get real data */
        locationManager.delegate = delegate
#endif
        if let userDefaults = userDefaults {
            // the checks before writing to the instance variable have two intentions:
            //   1. prevent a cached value replacing an updated/ more accurate value
            //   2. prevent a loop of:
            //
            //       ╭─→ write UserDefaults ─╮
            //       │                       │
            //       ╰──  observe change  ←──╯
            //
            
            // run placemark first since we don't want location to go
            //  and do a reverse geocode after finding that placemark is nil
            
            observer.observe(object: userDefaults, forKeyPath: stapledLocationUserDefaultsKey, options: .initial) { [weak self] change in
                guard let self = self else { return }
                let stapledLocation: StapledLocation?
                do {
                    stapledLocation = try userDefaults.decodedValue(forKey: self.stapledLocationUserDefaultsKey)
                } catch {
                    self.logger.error("decodedValue(forKey: \(self.stapledLocationUserDefaultsKey)): \(String(describing: error))")
                    return
                }
                guard let stapledLocation = stapledLocation else { return }
                if let current = self.stapledLocation {
                    // new location must be at least newer than the current
                    guard stapledLocation.location.timestamp.timeIntervalSince(current.location.timestamp) > 0 else { return }
                }
                self.stapledLocation = stapledLocation
            }
            
            observer.observe(object: userDefaults, forKeyPath: locationUserDefaultsKey, options: .initial) { [weak self] change in
                guard let self = self else { return }
                let location: CLLocation?
                do {
                    location = try userDefaults.unarchivedObject(forKey: self.locationUserDefaultsKey)
                } catch {
                    self.logger.error("unarchivedObject(forKey: \(self.locationUserDefaultsKey)): \(String(describing: error))")
                    return
                }
                guard let location = location else { return }
                if let currentLocation = self.location {
                    // new location must be at least newer than the current
                    guard location.timestamp.timeIntervalSince(currentLocation.timestamp) > 0 else { return }
                }
                self.location = location
            }
        }
    }
    
    deinit {
        activeGeocoder?.cancelGeocode()
    }
    
    private func stapledLocation(for location: CLLocation) async throws -> StapledLocation? {
        let placemark = stapledLocation?.placemark
        let placemarkLocationDistance = placemark?.location?.distance(from: location)
        // if this location is within a kilometer of the current placemark, skip it
        if let placemarkLocationDistance = placemarkLocationDistance,
           placemarkLocationDistance <= 1000 {
            return StapledLocation(placemark: placemark, location: location)
        }
        // if there's already an activeGeocoder, don't start another one
        if let activeGeocoder = activeGeocoder, activeGeocoder.isGeocoding { return nil }
        
        let geocoder = CLGeocoder()
        activeGeocoder = geocoder
        
        logger.debug("reverse geocoding: \(location)")
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return StapledLocation(placemark: placemarks.first, location: location)
        } catch {
            if let error = error as? CLError {
                self.logger.error("reverseGeocodeLocation: [\(error.code, privacy: .public)] \(error as NSError)")
            } else {
                self.logger.error("reverseGeocodeLocation: \(String(describing: error))")
            }
        }
        // once the placemark is over 5 kilometers away from the location,
        //   consider the placemark no longer representative of the location
        if let placemarkLocationDistance = placemarkLocationDistance,
           placemarkLocationDistance > 5000 {
            return StapledLocation(placemark: nil, location: location)
        }
        activeGeocoder = nil
        return StapledLocation(placemark: placemark, location: location)
    }
    
    public func override(location: CLLocation) {
        self.location = location
    }
    
    // MARK: - Requesting Authorization
    
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
#if os(iOS) || os(macOS) || os(watchOS)
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
#endif
    
    // MARK: - Updating Location
    
    public func requestLocation() {
        locationManager.requestLocation()
    }
#if os(iOS) || os(macOS) || os(watchOS)
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
#endif
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
#if os(iOS) || os(macOS)
    public func startMonitoringSignificantLocationChanges() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
    public func stopMonitoringSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
#endif
}

extension LocationManager {
    final class Delegate: NSObject, CLLocationManagerDelegate {
        private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "LocationManager.Delegate")
        
        weak var locationManager: LocationManager?
        
        public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            guard let locationManager = locationManager else {
                logger.notice("\(#function) called while locationManager is nil")
                return
            }
            logger.debug("locationManager.authorizationStatus = \(manager.authorizationStatus, privacy: .public)")
            locationManager.authorizationStatus = manager.authorizationStatus
        }
        
        public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let locationManager = locationManager else {
                logger.notice("\(#function) called while locationManager is nil")
                return
            }
            // we don't really want to set a nil location
            guard let location = manager.location ?? locations.max(by: { $0.timestamp < $1.timestamp }) else { return }
            logger.debug("locationManager.location = \(location)")
            locationManager.location = location
        }
        
        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            if let error = error as? CLError {
                logger.error("locationManagerDidFail: [\(error.code, privacy: .public)] \(error as NSError)")
            } else {
                logger.error("locationManagerDidFail: \(error as NSError))")
            }
        }
    }
}

extension CLLocationCoordinate2D {
    // https://en.wikipedia.org/wiki/Great-circle_navigation#Course
    public func course(to destination: CLLocationCoordinate2D) -> CLLocationDirection {
        let srcLat = self.latitude.radians()
        let srcLng = self.longitude.radians()
        
        let dstLat = destination.latitude.radians()
        let dstLng = destination.longitude.radians()
        
        let deltaLng = dstLng - srcLng
        let y = cos(dstLat) * sin(deltaLng)
        let x = cos(srcLat) * sin(dstLat) - sin(srcLat) * cos(dstLat) * cos(deltaLng)
        return atan2(y, x).degrees().constrict(to: Arithmetic.degreesInCircle)
    }
}

extension CLLocationCoordinate2D {
    public static let kaaba = CLLocationCoordinate2D(latitude: 21.422495, longitude: 39.826158)
}

extension CLPlacemark {
    public var locationTitle: String? {
        if let city = locality, let state = administrativeArea { return "\(city), \(state)" }
        if let city = locality, let country = country { return "\(city), \(country)" }
        if let neighborhood = subLocality, let country = country { return "\(neighborhood), \(country)" }
        if let state = administrativeArea, let country = country { return "\(state), \(country)" }
        if let country = country { return country }
        return nil
    }
}

extension CLLocation {
    public var coordinateText: String {
        let format: FloatingPointFormatStyle<CLLocationDegrees> = .number.precision(.fractionLength(4))
        return "(\(coordinate.latitude.formatted(format)), \(coordinate.longitude.formatted(format)))"
    }
}

extension CLAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized: Always"
        case .authorizedWhenInUse: return "Authorized: When In Use"
        @unknown default: return "@unknown (\(rawValue))"
        }
    }
}

extension CLError.Code: CustomStringConvertible {
    public var description: String {
        switch self {
        case .locationUnknown: return "Location Unknown"
        case .denied: return "Denied"
        case .network: return "Network"
        case .headingFailure: return "Heading Failure"
        case .regionMonitoringDenied: return "Region Monitoring Denied"
        case .regionMonitoringFailure: return "Region Monitoring Failure"
        case .regionMonitoringSetupDelayed: return "Region Monitoring Setup Delayed"
        case .regionMonitoringResponseDelayed: return "Region Monitoring Response Delayed"
        case .geocodeFoundNoResult: return "Geocode Found No Result"
        case .geocodeFoundPartialResult: return "Geocode Found Partial Result"
        case .geocodeCanceled: return "Geocode Canceled"
        case .deferredFailed: return "Deferred Failed"
        case .deferredNotUpdatingLocation: return "Deferred Not Updating Location"
        case .deferredAccuracyTooLow: return "Deferred Accuracy Too Low"
        case .deferredDistanceFiltered: return "Deferred Distance Filtered"
        case .deferredCanceled: return "Deferred Canceled"
        case .rangingUnavailable: return "Ranging Unavailable"
        case .rangingFailure: return "Ranging Failure"
        case .promptDeclined: return "Prompt Declined"
        case .historicalLocationError: return "Historical Location Error"
        @unknown default: return "@unknown (\(rawValue))"
        }
    }
}
