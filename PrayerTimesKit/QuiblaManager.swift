//
//  QuiblaManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/23/22.
//

import Foundation
import CoreLocation

public final class QuiblaManager: ObservableObject {
    public let locationManager: LocationManager
    public let headingManager: HeadingManager
    
    @Published public var quiblaCourse: CLLocationDirection?
    @Published public var quiblaHeading: CLLocationDirection?
    
    public init(locationManager: LocationManager, headingManager: HeadingManager) {
        self.locationManager = locationManager
        self.headingManager = headingManager
        
        locationManager.$location
            .map { location -> CLLocationDirection? in
                guard let location = location,
                      location.horizontalAccuracy >= 0 else { return nil }
                return location.coordinate.course(to: .kaaba)
            }
            .assign(to: &$quiblaCourse)
        
        headingManager.$heading
            .combineLatest($quiblaCourse) { heading, quiblaCourse -> CLLocationDirection? in
                guard let heading = heading,
                      let quiblaCourse = quiblaCourse else { return nil }
                let trueHeading = heading.trueHeading
                guard trueHeading >= 0 else { return nil }
                return quiblaCourse - trueHeading
            }
            .assign(to: &$quiblaHeading)
    }
}
