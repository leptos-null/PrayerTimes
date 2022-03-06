//
//  ContentView.swift
//  PrayerTimes
//
//  Created by Leptos on 1/22/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit
import PrayerTimesUI

struct ContentView: View {
    enum Tab: Int {
        case quibla, times, preferences
    }
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var preferences: Preferences
    let userNotificationManager: UserNotification.Manager
    
    @State var tab: Tab = .times
    
    let quiblaManager: QuiblaManager
    let orientationManager = OrientationManager(device: .current)
    
    init(locationManager: LocationManager = .shared, preferences: Preferences = .shared, userNotificationManager: UserNotification.Manager = .current) {
        self.locationManager = locationManager
        self.preferences = preferences
        self.quiblaManager = QuiblaManager(locationManager: locationManager, headingManager: HeadingManager())
        self.userNotificationManager = userNotificationManager
    }
    
    private func calculationParameters(for stapledLocation: StapledLocation) -> CalculationParameters {
        CalculationParameters(
            timeZone: stapledLocation.placemark?.timeZone ?? .current,
            location: stapledLocation.location,
            configuration: preferences.calculationConfiguration
        )
    }
    
    private func locationTitle(for stapledLocation: StapledLocation) -> String {
        stapledLocation.placemark?.locationTitle ?? stapledLocation.location.coordinateText
    }
    
    var body: some View {
        TabView(selection: $tab) {
            if let stapledLocation = locationManager.stapledLocation {
                QuiblaView(locationManager: locationManager, quiblaManager: quiblaManager, orientationManager: orientationManager, locationTitle: locationTitle(for: stapledLocation))
                    .tabItem {
                        Label("Quibla", systemImage: "location.north.line")
                    }
                    .tag(Tab.quibla)
                
                TimesView(calculationParameters: calculationParameters(for: stapledLocation), locationTitle: locationTitle(for: stapledLocation))
                    .tabItem {
                        Label("Times", systemImage: "clock")
                    }
                    .tag(Tab.times)
            } else {
                Text("Location unavailable")
                    .tabItem {
                        Label("Location", systemImage: "location")
                    }
                    .tag(Tab.times)
            }
            
            PreferencesView(preferences: preferences)
                .tabItem {
                    Label("Preferences", systemImage: "gear")
                }
                .tag(Tab.preferences)
        }
        .onReceive(userNotificationManager.$hasOpenSettingsRequest) { hasRequest in
            guard hasRequest else { return }
            tab = .preferences
            userNotificationManager.fulfillOpenSettingsRequest()
        }
        .onReceive(locationManager.$authorizationStatus) { authorizationStatus in
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
