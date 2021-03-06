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
    
    public var headingOrientation: CLDeviceOrientation {
        get { locationManager.headingOrientation }
        set { locationManager.headingOrientation = newValue }
    }
    
    public init() {
        locationManager.delegate = delegate
        locationManager.headingFilter = kCLHeadingFilterNone
        delegate.headingManager = self
    }
    
    public class func headingAvailable() -> Bool {
#if SCREENSHOT_MODE && !targetEnvironment(macCatalyst)
        true
#else
        CLLocationManager.headingAvailable()
#endif
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
