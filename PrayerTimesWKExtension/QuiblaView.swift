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
            Group {
                if let heading = quiblaManager.quiblaHeading {
                    SimpleCompass()
                        .aspectRatio(1, contentMode: .fit)
                        .rotationEffect(Angle(degrees: heading))
                } else {
                    Text("Direction unavailable")
                }
            }
            .onAppear(perform: quiblaManager.headingManager.startUpdatingHeading)
            .onDisappear(perform: quiblaManager.headingManager.stopUpdatingHeading)
        }
    }
}
