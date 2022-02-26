//
//  QuiblaView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/21/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

struct QuiblaView: View {
    enum Mode: Hashable {
        case compass
        case map
    }
    
    @State var mode: Mode = HeadingManager.headingAvailable() ? .compass : .map
    @ObservedObject var locationManager: LocationManager
    
    let quiblaManager: QuiblaManager
    let orientationManager: OrientationManager
    
    let locationTitle: String
    
    var body: some View {
        Group {
            switch mode {
            case .compass:
                VStack {
                    LocationHeader(title: locationTitle)
                    Spacer()
                    CompassView(quiblaManager: quiblaManager, orientationManager: orientationManager)
                }
                .scenePadding()
            case .map:
                if let location = locationManager.location {
                    QuiblaMapView(sourceCoordinate: location.coordinate)
                        .ignoresSafeArea(.all, edges: .top)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if HeadingManager.headingAvailable() {
                Button {
                    switch mode {
                    case .compass: mode = .map
                    case .map: mode = .compass
                    }
                } label: {
                    switch mode {
                    case .compass:
                        Label("Map", systemImage: "map")
                    case .map:
                        Label("Compass", systemImage: "gyroscope") // TODO: compass icon
                    }
                }
                .font(.title)
                .buttonStyle(.borderedProminent)
                .labelStyle(.iconOnly)
                .aspectRatio(1, contentMode: .fit)
                .scenePadding()
            }
        }
    }
}
