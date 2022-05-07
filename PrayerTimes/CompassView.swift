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
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private let orientationCancellable: AnyCancellable
    
    init(quiblaManager: QuiblaManager, orientationManager: OrientationManager) {
        self.quiblaManager = quiblaManager
        
        orientationCancellable = orientationManager.$orientation
            .map { CLDeviceOrientation($0) }
            .assign(to: \.headingOrientation, on: quiblaManager.headingManager)
    }
    
    var body: some View {
        Group {
            switch quiblaManager.snapAdjustedHeading {
            case .success(let heading):
                LineUpCompass(facing: Angle(degrees: heading))
                    .accessibilityLabel("Quibla direction")
                    .accessibilityValue(QuiblaManager.directionDescription(for: heading))
                    .accessibilityAddTraits(.updatesFrequently)
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
        .onAppear(perform: quiblaManager.headingManager.startUpdatingHeading)
        .onDisappear(perform: quiblaManager.headingManager.stopUpdatingHeading)
        .onReceive(quiblaManager.enteredSnapAdjustment) {
            impactGenerator.impactOccurred()
        }
    }
}
