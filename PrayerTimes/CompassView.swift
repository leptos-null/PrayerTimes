//
//  CompassView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/21/22.
//

#if os(iOS)

import SwiftUI
import CoreLocation
import PrayerTimesUI
import PrayerTimesKit
import Combine

struct CompassView: View {
    @ObservedObject private var qiblaManager: QiblaManager
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private let orientationCancellable: AnyCancellable
    
    init(qiblaManager: QiblaManager, orientationManager: OrientationManager) {
        self.qiblaManager = qiblaManager
        
        orientationCancellable = orientationManager.$orientation
            .map { CLDeviceOrientation($0) }
            .assign(to: \.headingOrientation, on: qiblaManager.headingManager)
    }
    
    var body: some View {
        Group {
            switch qiblaManager.snapAdjustedHeading {
            case .success(let heading):
                LineUpCompass(facing: Angle(degrees: heading))
                    .accessibilityLabel("Qibla direction")
                    .accessibilityValue(QiblaManager.directionDescription(for: heading))
                    .accessibilityAddTraits(.updatesFrequently)
            case .failure(let error):
                Text(error.localizedDescription)
            }
        }
        .onAppear(perform: qiblaManager.headingManager.startUpdatingHeading)
        .onDisappear(perform: qiblaManager.headingManager.stopUpdatingHeading)
        .onReceive(qiblaManager.enteredSnapAdjustment) {
            impactGenerator.impactOccurred()
        }
    }
}

#endif
