//
//  OverrideLocationView.swift
//  PrayerTimes
//
//  Created by Leptos on 3/29/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import CoreLocationUI

struct OverrideLocationView: View {
    @ObservedObject var locationManager: LocationManager
    
    @State private var coordinate: CLLocationCoordinate2D?
    
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
            .disabled((locationManager.location?.coordinate == coordinate) && (coordinate != nil))
            
            CoordinatePicker(coordinate: $coordinate)
                .overlay(alignment: .topTrailing) {
                    LocationButton(action: locationManager.startUpdatingLocation)
                        .symbolVariant(.fill)
                        .labelStyle(.iconOnly)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .scenePadding()
                }
                .cornerRadius(8)
                .padding()
        }
        .onAppear {
            // we don't want to have this tied up always, because we don't want a new location coming in
            //   and then the user's selection changes by itself, potentially losing their current selection
            if let location = locationManager.location {
                coordinate = location.coordinate
            }
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
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
