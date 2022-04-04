//
//  LocationPrompt.swift
//  PrayerTimes
//
//  Created by Leptos on 3/29/22.
//

import SwiftUI
import PrayerTimesKit

struct LocationPrompt: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        if locationManager.authorizationStatus != .restricted {
            GeometryReader { geometryProxy in
                VStack {
                    VStack {
                        Spacer()
                        
                        Text("Enable Location Access to always see prayer times for your current location.")
                            .padding()
                        
                        Button {
                            locationManager.requestWhenInUseAuthorization()
                        } label: {
                            Label("Enable Location Access", systemImage: "location")
                                .symbolVariant(.fill)
                        }
                        .buttonStyle(.borderedProminent)
                        .hoverEffect()
                        .disabled(locationManager.authorizationStatus != .notDetermined)
                        
                        HStack {
                            Text("Open Settings to Enable Location Services")
                            Link(destination: URL(string: "https://support.apple.com/HT207092")!) {
                                Label("Help", systemImage: "questionmark.circle")
                                    .labelStyle(.iconOnly)
                            }
                            .hoverEffect()
                        }
                        .font(.callout)
                        .opacity((locationManager.authorizationStatus == .denied) ? 1 : 0)
                        
                        Spacer()
                    }
                    .frame(height: geometryProxy.size.height * 0.32)
                    
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                        Text("or")
                            .font(.callout.smallCaps())
                        Rectangle()
                            .frame(height: 1)
                    }
                    OverrideLocationView(locationManager: locationManager)
                }
            }
        } else {
            OverrideLocationView(locationManager: locationManager)
                .scenePadding(.top)
        }
    }
}

struct LocationPrompt_Previews: PreviewProvider {
    static var previews: some View {
        LocationPrompt(locationManager: .shared)
    }
}
