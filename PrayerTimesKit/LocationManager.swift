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
    
    private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "LocationManager")
    
    private let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup")
    private let locationUserDefaultsKey = "LocationManagerLocationKey"
    private let placemarkUserDefaultsKey = "LocationManagerPlacemarkKey"
    
    @Published public private(set) var location: CLLocation? {
        didSet {
            guard let location = location else {
                logger.log("location set to nil")
                return
            }
            reverseGeocodeIfNeeded(location)
            
            guard let userDefaults = userDefaults else { return }
            logger.debug("archiving: \(location)")
            do {
                try userDefaults.setArchived(object: location, forKey: locationUserDefaultsKey)
            } catch {
                logger.error("setArchived(object: \(location), forKey: \(self.locationUserDefaultsKey)): \(String(describing: error))")
            }
        }
    }
    @Published public private(set) var heading: CLHeading?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    
    @Published public private(set) var placemark: CLPlacemark? {
        didSet {
            guard let userDefaults = userDefaults else { return }
            if let placemark = placemark {
                logger.debug("archiving: \(placemark)")
                do {
                    try userDefaults.setArchived(object: placemark, forKey: placemarkUserDefaultsKey)
                } catch {
                    logger.error("setArchived(object: \(placemark), forKey: \(self.placemarkUserDefaultsKey)): \(String(describing: error))")
                }
            } else {
                logger.log("placemark set to nil")
                userDefaults.removeObject(forKey: placemarkUserDefaultsKey)
            }
        }
    }
    
    private var activeGeocoder: CLGeocoder?
    
    init() {
        // read from cache before setting up CLLocationManager in case updated locations come in very quickly
        if let userDefaults = userDefaults {
            do {
                location = try userDefaults.unarchivedObject(forKey: locationUserDefaultsKey)
            } catch {
                logger.error("unarchivedObject(forKey: \(self.locationUserDefaultsKey)): \(String(describing: error))")
            }
            do {
                placemark = try userDefaults.unarchivedObject(forKey: placemarkUserDefaultsKey)
            } catch {
                logger.error("unarchivedObject(forKey: \(self.placemarkUserDefaultsKey)): \(String(describing: error))")
            }
            // TODO: listen for changes on userDefaults
        }
        
        locationManager.distanceFilter = 500
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
        
        delegate.locationManager = self
        locationManager.delegate = delegate
    }
    
    deinit {
        activeGeocoder?.cancelGeocode()
    }
    
    private func reverseGeocodeIfNeeded(_ location: CLLocation) {
        let placemarkLocationDistance = placemark?.location?.distance(from: location)
        // if this location is within a kilometer of the current placemark, skip it
        if let placemarkLocationDistance = placemarkLocationDistance,
           placemarkLocationDistance <= 1000 { return }
        
        // if there's already an activeGeocoder, don't start another one
        if let activeGeocoder = activeGeocoder, activeGeocoder.isGeocoding { return }
        
        let geocoder = CLGeocoder()
        activeGeocoder = geocoder
        
        Task(priority: .background) { [weak self] in
            guard let self = self else { return }
            self.logger.debug("reverse geocoding: \(location)")
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let placemark = placemarks.first else {
                    self.logger.log("reverseGeocodeLocation did not return any placemarks")
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.placemark = placemark
                }
            } catch {
                // once the placemark is over 5 kilometers away from the location,
                //   consider the placemark no longer representative of the location
                if let placemarkLocationDistance = placemarkLocationDistance,
                   placemarkLocationDistance > 5000 {
                    DispatchQueue.main.async { [weak self] in
                        self?.placemark = nil
                    }
                }
                if let error = error as? CLError {
                    self.logger.error("reverseGeocodeLocation: [\(error.code, privacy: .public)] \(error as NSError)")
                } else {
                    self.logger.error("reverseGeocodeLocation: \(String(describing: error))")
                }
            }
            self.activeGeocoder = nil
        }
    }
    
    public func override(location: CLLocation) {
        self.location = location
    }
    
    // MARK: - Requesting Authorization
    
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Updating Location
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Updating Heading
    
    public class func headingAvailable() -> Bool {
        CLLocationManager.headingAvailable()
    }
    
    public func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
#if os(iOS) || os(watchOS)
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
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
            logger.debug("locationManager.location = \(String(describing: manager.location))")
            locationManager.location = manager.location
        }
        
        public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let locationManager = locationManager else {
                logger.notice("\(#function) called while locationManager is nil")
                return
            }
            logger.debug("locationManager.heading = \(String(describing: newHeading))")
            locationManager.heading = newHeading
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

extension UserDefaults {
    func unarchivedObject<Object>(forKey key: String) throws -> Object? where Object: NSObject, Object: NSSecureCoding {
        guard let data = data(forKey: key) else { return nil }
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)
    }
    
    func setArchived<Object>(object: Object, forKey key: String) throws where Object: NSObject, Object: NSSecureCoding {
        let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        set(data, forKey: key)
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
        @unknown default: return "@unknown (\(rawValue))"
        }
    }
}
