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
    @ObservedObject private var quiblaManager: QuiblaManager
    @ObservedObject private var orientationManager: OrientationManager
    
    private let orientationCancellable: AnyCancellable
    
    init(quiblaManager: QuiblaManager, orientationManager: OrientationManager) {
        self.quiblaManager = quiblaManager
        self.orientationManager = orientationManager
        
        orientationCancellable = orientationManager.$orientation
            .map { CLDeviceOrientation($0) }
            .assign(to: \.headingOrientation, on: quiblaManager.headingManager)
    }
    
    var body: some View {
        Group {
            if let heading = quiblaManager.quiblaHeading {
                LineUpCompass(facing: Angle(degrees: heading))
            } else {
                Text("Direction unavailable")
            }
        }
        .onAppear(perform: quiblaManager.headingManager.startUpdatingHeading)
        .onDisappear(perform: quiblaManager.headingManager.stopUpdatingHeading)
    }
}
