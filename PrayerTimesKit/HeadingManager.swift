//
//  HeadingManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/6/22.
//

import Foundation
import CoreLocation
import os

#if os(iOS) || os(watchOS)

public final class HeadingManager: ObservableObject {
    private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "HeadingManager")
    
    private let locationManager = CLLocationManager()
    private let delegate = Delegate()
    
    @Published public private(set) var heading: CLHeading?
    
    public var headingFilter: CLLocationDegrees {
        get { locationManager.headingFilter }
        set { locationManager.headingFilter = newValue }
    }
    public var headingOrientation: CLDeviceOrientation {
        get { locationManager.headingOrientation }
        set { locationManager.headingOrientation = newValue }
    }
    
    public init() {
        locationManager.delegate = delegate
        delegate.headingManager = self
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
    
    deinit {
        stopUpdatingHeading()
    }
}

extension HeadingManager {
    private final class Delegate: NSObject, CLLocationManagerDelegate {
        private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "HeadingManager.Delegate")
        
        weak var headingManager: HeadingManager?
        
        public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            guard let headingManager = headingManager else {
                Self.logger.notice("\(#function) called while headingManager is nil")
                return
            }
            Self.logger.debug("headingManager.heading = \(String(describing: newHeading))")
            headingManager.heading = newHeading
        }
        
        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            if let error = error as? CLError {
                Self.logger.error("locationManagerDidFail: [\(error.code, privacy: .public)] \(error as NSError)")
            } else {
                Self.logger.error("locationManagerDidFail: \(error as NSError))")
            }
        }
    }
}

#endif
