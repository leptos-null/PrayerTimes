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
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    public class func headingAvailable() -> Bool {
        CLLocationManager.headingAvailable()
    }
    
    public func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
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
