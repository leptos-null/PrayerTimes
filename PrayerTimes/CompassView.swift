//
//  CompassView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/21/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesUI
import PrayerTimesKit
import Combine

struct CompassView: View {
    @ObservedObject private var headingManager: HeadingManager
    @ObservedObject private var locationManager: LocationManager
    @ObservedObject private var orientationManager: OrientationManager
    
    private let orientationCancellable: AnyCancellable
    
    init(headingManager: HeadingManager, locationManager: LocationManager = .shared, orientationManager: OrientationManager) {
        self.headingManager = headingManager
        self.locationManager = locationManager
        self.orientationManager = orientationManager
        
        orientationCancellable = orientationManager.$orientation
            .map { CLDeviceOrientation($0) }
            .assign(to: \.headingOrientation, on: headingManager)
    }
    
    var angle: Angle? {
        guard let heading = headingManager.heading,
              let location = locationManager.location else { return nil }
        let trueHeading = heading.trueHeading
        guard trueHeading > 0, // valid heading
              location.horizontalAccuracy >= 0 else { return nil } // valid coordinate
        // TODO: avoid re-calculating course every time
        let angle = location.coordinate.course(to: .kaaba) - trueHeading
        return Angle(degrees: angle)
    }
    
    var body: some View {
        Group {
            if let angle = angle {
                LineUpCompass(facing: angle)
            } else {
                Text("Direction unavailable")
            }
        }
        .onAppear(perform: headingManager.startUpdatingHeading)
        .onDisappear(perform: headingManager.stopUpdatingHeading)
    }
}
