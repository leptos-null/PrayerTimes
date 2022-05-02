//
//  QuiblaView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/19/22.
//

import SwiftUI
import PrayerTimesUI
import PrayerTimesKit

struct QuiblaView: View {
    @ObservedObject var quiblaManager: QuiblaManager
    
    var body: some View {
        // in my testing, headingManager reacts very well to orientation changes by itself on watchOS
        if HeadingManager.headingAvailable() {
            NavigationView {
                Group {
                    switch quiblaManager.snapAdjustedHeading {
                    case .success(let heading):
                        SimpleCompass()
                            .aspectRatio(1, contentMode: .fit)
                            .rotationEffect(Angle(degrees: heading))
                    case .failure(let error):
                        Text(error.localizedDescription)
                    }
                }
                .onAppear(perform: quiblaManager.headingManager.startUpdatingHeading)
                .onDisappear(perform: quiblaManager.headingManager.stopUpdatingHeading)
                .navigationTitle("Quibla")
                .navigationBarTitleDisplayMode(.inline)
                .onReceive(quiblaManager.enteredSnapAdjustment) {
                    WKInterfaceDevice.current().play(.click)
                }
            }
        }
    }
}
