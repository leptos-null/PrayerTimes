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
        case qibla, times, preferences
    }
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var preferences: Preferences
    let userNotificationManager: UserNotification.Manager
    let preferencesViewModel = PreferencesViewModel()
    
    @State var tab: Tab = .times
    
    let qiblaManager: QiblaManager
    let orientationManager = OrientationManager(device: .current)
    
    init(locationManager: LocationManager = .shared, preferences: Preferences = .shared, userNotificationManager: UserNotification.Manager = .current) {
        self.locationManager = locationManager
        self.preferences = preferences
        self.qiblaManager = QiblaManager(locationManager: locationManager, headingManager: HeadingManager())
        self.userNotificationManager = userNotificationManager
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
            if let stapledLocation = locationManager.stapledLocation {
                QiblaView(locationManager: locationManager, qiblaManager: qiblaManager, orientationManager: orientationManager, locationTitle: locationTitle(for: stapledLocation))
                    .tabItem {
                        Label("Qibla", systemImage: "location.north.line")
                    }
                    .tag(Tab.qibla)
                
                TimesView(calculationParameters: calculationParameters(for: stapledLocation), locationTitle: locationTitle(for: stapledLocation))
                    .environment(\.visiblePrayers, preferences.visiblePrayers)
                    .tabItem {
                        Label("Times", systemImage: "clock")
                    }
                    .tag(Tab.times)
            } else {
                LocationPrompt(locationManager: locationManager)
                    .tabItem {
                        Label("Location", systemImage: "location")
                    }
                    .tag(Tab.times)
            }
            
            PreferencesView(locationManager: locationManager, preferences: preferences, viewModel: preferencesViewModel)
                .tabItem {
                    Label("Preferences", systemImage: "gear")
                }
                .tag(Tab.preferences)
        }
        .onReceive(userNotificationManager.$settingsRequest) { settingsRequest in
            guard case .active(let category) = settingsRequest else { return }
            
            let preferenceSelection: PreferencesView.NavigationSelection?
            if let category = category {
                preferenceSelection = .notification(category)
            } else {
                preferenceSelection = .none
            }
            tab = .preferences
            preferencesViewModel.navigationSelection = preferenceSelection
            
            userNotificationManager.fulfillOpenSettingsRequest()
        }
        .onReceive(locationManager.$authorizationStatus) { authorizationStatus in
#if SCREENSHOT_MODE
            locationManager.override(location: CLLocation(latitude: 37.334886, longitude: -122.008988))
#else
            switch authorizationStatus {
            case .notDetermined:
                break
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
