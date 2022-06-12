//
//  QiblaView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/19/22.
//

import SwiftUI
import PrayerTimesUI
import PrayerTimesKit

struct QiblaView: View {
    @ObservedObject var qiblaManager: QiblaManager
    
    var body: some View {
        // in my testing, headingManager reacts very well to orientation changes by itself on watchOS
        if HeadingManager.headingAvailable() {
            NavigationView {
                Group {
                    switch qiblaManager.snapAdjustedHeading {
                    case .success(let heading):
                        SimpleCompass()
                            .aspectRatio(1, contentMode: .fit)
                            .rotationEffect(Angle(degrees: heading))
                            .accessibilityLabel("Qibla direction")
                            .accessibilityValue(QiblaManager.directionDescription(for: heading))
                            .accessibilityAddTraits(.updatesFrequently)
                    case .failure(let error):
                        Text(error.localizedDescription)
                    }
                }
                .onAppear(perform: qiblaManager.headingManager.startUpdatingHeading)
                .onDisappear(perform: qiblaManager.headingManager.stopUpdatingHeading)
                .navigationTitle("Qibla")
                .navigationBarTitleDisplayMode(.inline)
                .onReceive(qiblaManager.enteredSnapAdjustment) {
                    WKInterfaceDevice.current().play(.click)
                }
            }
        }
    }
}
