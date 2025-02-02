//
//  QiblaView.swift
//  PrayerTimes
//
//  Created by Leptos on 2/21/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

#if os(iOS)

struct QiblaView: View {
    enum Mode: Hashable {
        case compass
        case map
    }
    
    @State var mode: Mode = HeadingManager.headingAvailable() ? .compass : .map
    @ObservedObject var locationManager: LocationManager
    
    let qiblaManager: QiblaManager
    let orientationManager: OrientationManager
    
    let locationTitle: String
    
    var body: some View {
        Group {
            switch mode {
            case .compass:
                VStack(spacing: 0) {
                    LocationHeader(title: locationTitle)
                    Spacer()
                    CompassView(qiblaManager: qiblaManager, orientationManager: orientationManager)
                }
                .scenePadding()
            case .map:
                if let location = locationManager.location {
                    QiblaMapView(sourceCoordinate: location.coordinate)
                        .ignoresSafeArea(.all)
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
                .hoverEffect()
                .aspectRatio(1, contentMode: .fit)
                .scenePadding()
            }
        }
    }
}

#else

struct QiblaView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        if let location = locationManager.location {
            QiblaMapView(sourceCoordinate: location.coordinate)
                .ignoresSafeArea(.all, edges: .top)
        }
    }
}

#endif
