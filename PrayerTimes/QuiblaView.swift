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
    
    @StateObject var headingManager = HeadingManager()
    @ObservedObject var locationManager: LocationManager = .shared
    @StateObject var orientationManager = OrientationManager(device: .current)
    
    var locationTitle: String {
        if let placemarkTitle = locationManager.placemark?.locationTitle {
            return placemarkTitle
        }
        guard let coordinate = locationManager.location?.coordinate else { return "Location Unknown" }
        let format: FloatingPointFormatStyle<CLLocationDegrees> = .number.precision(.fractionLength(4))
        return "\(coordinate.latitude.formatted(format)), \(coordinate.longitude.formatted(format)))"
    }
    
    var body: some View {
        Group {
            switch mode {
            case .compass:
                VStack {
                    Text(locationTitle)
                    Spacer()
                    CompassView(headingManager: headingManager, locationManager: locationManager, orientationManager: orientationManager)
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

struct QuiblaView_Previews: PreviewProvider {
    static var previews: some View {
        QuiblaView()
    }
}
