//
//  QuiblaManager.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/23/22.
//

import Foundation
import CoreLocation
import Combine

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
    
    /// A human readable string that describes `heading` with respect to the observer
    ///
    /// A value of "40 degrees left" means that in order to be facing forward,
    /// the observer should rotate 40 degrees to their left.
    public static func directionDescription(for heading: CLLocationDirection) -> String {
        if heading == 0 {
            return "Forward"
        }
        
        let isTowardsLeft = (heading > 180)
        let relativeDirection = isTowardsLeft ? "left" : "right"
        let offsetAngle = isTowardsLeft ? (360 - heading) : (0 + heading)
        let formattedAngle = Measurement(value: offsetAngle, unit: UnitAngle.degrees)
            .formatted(.measurement(width: .wide, usage: .general, numberFormatStyle: .number.precision(.fractionLength(0))))
        return "\(formattedAngle) \(relativeDirection)"
    }
    
    public let locationManager: LocationManager
    public let headingManager: HeadingManager
    
    @Published public var forwardEpsilon: CLLocationDirectionAccuracy
    
    @Published public private(set) var quiblaCourse: Result<CLLocationDirection, Error>
    @Published public private(set) var quiblaHeading: Result<CLLocationDirection, Error>
    @Published public private(set) var snapAdjustedHeading: Result<CLLocationDirection, Error>
    
    
    public private(set) lazy var enteredSnapAdjustment: AnyPublisher<Void, Never> = {
        $snapAdjustedHeading
            .map { snapAdjustedHeading in
                switch snapAdjustedHeading {
                case .success(let heading):
                    return (heading == 0)
                case .failure:
                    return false
                }
            }
            .removeDuplicates()
            .filter { $0 }
            .map { _ -> Void in
            }
            .eraseToAnyPublisher()
    }()
    
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
        case .success(let course):
            let delta = course - trueHeading
            return .success(delta.constrict(to: Arithmetic.degreesInCircle))
        case .failure(let error):
            return .failure(error)
        }
#endif
    }
    
    private static func snapAdjustedHeadingFor(quiblaHeading: Result<CLLocationDirection, Error>, forwardEpsilon: CLLocationDirectionAccuracy) -> Result<CLLocationDirection, Error> {
        switch quiblaHeading {
        case .success(let heading):
            let circle: Range<CLLocationDirection> = 0..<360
            let range = (circle.lowerBound + forwardEpsilon)..<(circle.upperBound - forwardEpsilon)
            let inRange = range.contains(heading)
            return .success(inRange ? heading : 0)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public init(locationManager: LocationManager, headingManager: HeadingManager, forwardEpsilon: CLLocationDirectionAccuracy = 0.5) {
        self.locationManager = locationManager
        self.headingManager = headingManager
        
        let quiblaCourse = Self.quiblaCourse(for: locationManager.location)
        let quiblaHeading = Self.quiblaHeadingFor(heading: headingManager.heading, quiblaCourse: quiblaCourse)
        let snapAdjustedHeading = Self.snapAdjustedHeadingFor(quiblaHeading: quiblaHeading, forwardEpsilon: forwardEpsilon)
        
        self.quiblaCourse = quiblaCourse
        self.quiblaHeading = quiblaHeading
        self.snapAdjustedHeading = snapAdjustedHeading
        self.forwardEpsilon = forwardEpsilon
        
        locationManager.$location
            .map(Self.quiblaCourse(for:))
            .assign(to: &$quiblaCourse)
        
        headingManager.$heading
            .combineLatest($quiblaCourse, Self.quiblaHeadingFor(heading:quiblaCourse:))
            .assign(to: &$quiblaHeading)
        
        $quiblaHeading
            .combineLatest($forwardEpsilon, Self.snapAdjustedHeadingFor(quiblaHeading:forwardEpsilon:))
            .assign(to: &$snapAdjustedHeading)
    }
}

#endif
