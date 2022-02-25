//
//  QuiblaManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/23/22.
//

import Foundation
import CoreLocation
import os

#if os(iOS) || os(watchOS)

public final class QuiblaManager: ObservableObject {
    private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "QuiblaManager")
    
    public let locationManager: LocationManager
    public let headingManager: HeadingManager
    
    @Published public private(set) var quiblaCourse: CLLocationDirection?
    @Published public private(set) var quiblaHeading: CLLocationDirection?
    
    public init(locationManager: LocationManager, headingManager: HeadingManager) {
        self.locationManager = locationManager
        self.headingManager = headingManager
        
        locationManager.$location
            .map { location -> CLLocationDirection? in
                guard let location = location,
                      location.horizontalAccuracy >= 0 else {
                          Self.logger.notice("location is nil or coordinate is not valid")
                          return nil
                      }
                return location.coordinate.course(to: .kaaba)
            }
            .assign(to: &$quiblaCourse)
        
        headingManager.$heading
            .combineLatest($quiblaCourse) { heading, quiblaCourse -> CLLocationDirection? in
                guard let heading = heading,
                      let quiblaCourse = quiblaCourse else {
                          Self.logger.notice("heading or quiblaCourse is nil")
                          return nil
                      }
                let trueHeading = heading.trueHeading
                guard trueHeading >= 0 else {
                    Self.logger.notice("trueHeading is not valid")
                    return nil
                }
                return quiblaCourse - trueHeading
            }
            .assign(to: &$quiblaHeading)
    }
}

#endif
