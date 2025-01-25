//
//  OverrideLocationView.swift
//  PrayerTimes
//
//  Created by Leptos on 3/29/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
#if canImport(CoreLocationUI)
import CoreLocationUI
#endif

struct OverrideLocationView: View {
    @ObservedObject var locationManager: LocationManager
    
    @State private var coordinate: CLLocationCoordinate2D?
    
    private var isCoordinateOriginal: Bool {
        locationManager.location?.coordinate == coordinate
    }
    
    var body: some View {
        VStack {
            Text("Long press on the map to drop a pin.")
                .padding()
            Button {
                guard let coordinate = coordinate else { return }
                locationManager.override(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            } label: {
                Label("Use Selected", systemImage: "mappin.and.ellipse")
            }
            .buttonStyle(.bordered)
            .hoverEffect()
            .disabled(isCoordinateOriginal || (coordinate == nil))
            
            Group {
#if canImport(CoreLocationUI)
                CoordinatePicker(coordinate: $coordinate)
                    .overlay(alignment: .topTrailing) {
                        LocationButton(action: locationManager.startUpdatingLocation)
                            .symbolVariant(.fill)
                            .labelStyle(.iconOnly)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .scenePadding()
                    }
#else
                CoordinatePicker(coordinate: $coordinate)
#endif
            }
            .cornerRadius(8)
            .padding()
        }
        .onReceive(locationManager.$location) { location in
            guard let location = location else { return }
            // Published publishes before its wrapped value updates
            // this behavior allows the input parameter to this block be the new value
            // while `locationManager.location` still has the previous value
            guard (coordinate == nil) || isCoordinateOriginal else { return }
            coordinate = location.coordinate
        }
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        let epsilon: CLLocationDegrees = 1e-8
        let latitudeDiff = lhs.latitude.distance(to: rhs.latitude).magnitude
        let longitudeDiff = lhs.longitude.distance(to: rhs.longitude).magnitude
        return (latitudeDiff <= epsilon) && (longitudeDiff <= epsilon)
    }
}

struct OverrideLocationView_Previews: PreviewProvider {
    static var previews: some View {
        OverrideLocationView(locationManager: .shared)
    }
}
