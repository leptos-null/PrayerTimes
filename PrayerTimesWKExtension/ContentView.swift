//
//  ContentView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/18/22.
//

import SwiftUI
import PrayerTimesKit
import PrayerTimesUI

struct ContentView: View {
    enum Tab: Int {
        case qibla, times, preferences
    }
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var preferences: Preferences
    
    @State var tab: Tab = .times
    
    let qiblaManager: QiblaManager
    
    init(locationManager: LocationManager = .shared, preferences: Preferences = .shared) {
        self.locationManager = locationManager
        self.preferences = preferences
        self.qiblaManager = QiblaManager(locationManager: locationManager, headingManager: HeadingManager())
    }
    
    private func calculationParameters(for stapledLocation: StapledLocation) -> CalculationParameters {
        CalculationParameters(
            timeZone: stapledLocation.placemark?.timeZone ?? .current,
            location: stapledLocation.location,
            configuration: preferences.calculationMethod.calculationConfiguration
        )
    }
    
    private func locationTitle(for stapledLocation: StapledLocation) -> String {
        stapledLocation.placemark?.locationTitle ?? stapledLocation.location.coordinateText
    }
    
    var body: some View {
        TabView(selection: $tab) {
            QiblaView(qiblaManager: qiblaManager)
                .tag(Tab.qibla)
            
            if let stapledLocation = locationManager.stapledLocation {
                TimesView(calculationParameters: calculationParameters(for: stapledLocation), locationTitle: locationTitle(for: stapledLocation))
                    .environment(\.visiblePrayers, preferences.visiblePrayers)
                    .tag(Tab.times)
            } else {
                Text("Location unavailable")
                    .tag(Tab.times)
            }
            
            PreferencesView(preferences: preferences)
                .tag(Tab.preferences)
        }
        .onReceive(locationManager.$authorizationStatus) { authorizationStatus in
#if SCREENSHOT_MODE
            locationManager.override(location: CLLocation(latitude: 37.334886, longitude: -122.008988))
#else
            switch authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                break
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            @unknown default:
                break
            }
#endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
