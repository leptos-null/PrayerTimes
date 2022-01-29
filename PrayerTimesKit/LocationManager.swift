//
//  LocationManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/25/22.
//

import Foundation
import CoreLocation

public final class LocationManager: ObservableObject {
    private let locationManager = CLLocationManager()
    private let delegate = Delegate()
    
    @Published public private(set) var location: CLLocation?
    @Published public private(set) var heading: CLHeading?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    
    public init() {
        locationManager.distanceFilter = 500
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = delegate
        authorizationStatus = locationManager.authorizationStatus
        
        delegate.locationManager = self
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
        weak var locationManager: LocationManager?
        
        public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            locationManager?.authorizationStatus = manager.authorizationStatus
        }
        
        public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            locationManager?.location = manager.location
        }
        
        public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            locationManager?.heading = newHeading
        }
        
        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("locationManager", "didFailWithError", error)
        }
    }
}
