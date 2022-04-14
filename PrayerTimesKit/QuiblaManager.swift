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
    public enum Error: Swift.Error {
        case locationMissing
        case coordinateInvalid
        case headingMissing
        case trueHeadingInvalid
        
        public var localizedDescription: String {
            switch self {
            case .locationMissing:
                return "Location unavailable"
            case .coordinateInvalid:
                return "Location coordinate is not valid"
            case .headingMissing:
                return "Device heading unavailable"
            case .trueHeadingInvalid:
                return "True heading is not valid"
            }
        }
    }
    
    public let locationManager: LocationManager
    public let headingManager: HeadingManager
    
    @Published public private(set) var quiblaCourse: Result<CLLocationDirection, Error>
    @Published public private(set) var quiblaHeading: Result<CLLocationDirection, Error>
    
    private static func quiblaCourse(for location: CLLocation?) -> Result<CLLocationDirection, Error> {
        guard let location = location else { return .failure(.locationMissing) }
        guard location.horizontalAccuracy >= 0 else { return .failure(.coordinateInvalid) }
        return .success(location.coordinate.course(to: .kaaba))
    }
    
    private static func quiblaHeadingFor(heading: CLHeading?, quiblaCourse: Result<CLLocationDirection, Error>) -> Result<CLLocationDirection, Error> {
#if SCREENSHOT_MODE
        return .success(30)
#else
        guard let heading = heading else { return .failure(.headingMissing) }
        let trueHeading = heading.trueHeading
        guard trueHeading >= 0 else { return .failure(.trueHeadingInvalid) }
        
        switch quiblaCourse {
        case .success(let course): return .success(course - trueHeading)
        case .failure(let error):  return .failure(error)
        }
#endif
    }
    
    public init(locationManager: LocationManager, headingManager: HeadingManager) {
        self.locationManager = locationManager
        self.headingManager = headingManager
        
        let quiblaCourse = Self.quiblaCourse(for: locationManager.location)
        self.quiblaCourse = quiblaCourse
        self.quiblaHeading = Self.quiblaHeadingFor(heading: headingManager.heading, quiblaCourse: quiblaCourse)
        
        locationManager.$location
            .map(Self.quiblaCourse(for:))
            .assign(to: &$quiblaCourse)
        
        headingManager.$heading
            .combineLatest($quiblaCourse, Self.quiblaHeadingFor(heading:quiblaCourse:))
            .assign(to: &$quiblaHeading)
    }
}

#endif
