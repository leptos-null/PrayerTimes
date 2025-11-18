//
//  PreferencesView.swift
//  PrayerTimes
//
//  Created by Leptos on 3/22/22.
//

import SwiftUI
import PrayerTimesUI
import PrayerTimesKit

struct PreferencesView: View {
    enum NavigationSelection: Hashable {
        case selectLocation
        case visibility, calculationMethod
        case notification(UserNotification.Category)
    }
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var preferences: Preferences
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    private var listStyle: some ListStyle {
#if targetEnvironment(macCatalyst)
        return .plain
#else
        return .insetGrouped
#endif
    }
    
    private var shouldShowLocationSection: Bool {
        switch locationManager.authorizationStatus {
        case .notDetermined, .restricted, .denied: return true
        case .authorizedAlways, .authorizedWhenInUse: return false
        @unknown default: return true
        }
    }
    
    private func notificationCategoryBinding(_ category: UserNotification.Category) -> Binding<Set<Prayer.Name>> {
        Binding {
            preferences.userNotifications.categories[category] ?? Set()
        } set: {
            preferences.userNotifications.categories[category] = $0
        }
    }
    
    var body: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                NavigationSplitView {
                    List(selection: $viewModel.navigationSelection) {
                        if shouldShowLocationSection {
                            Section {
                                NavigationLink("Select Location", value: NavigationSelection.selectLocation)
                            } header: {
                                Label("Location", systemImage: "location")
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                        
                        Section {
                            NavigationLink("Visibility", value: NavigationSelection.visibility)
                            NavigationLink("Calculation Method", value: NavigationSelection.calculationMethod)
                        } header: {
                            Label("Configuration", systemImage: "gear")
                                .symbolRenderingMode(.multicolor)
                        }
                        
                        Section {
                            ForEach(UserNotification.Category.allCases) { category in
                                NavigationLink(category.localizedTitle, value: PreferencesView.NavigationSelection.notification(category))
                            }
                        } header: {
                            Label("Notifications", systemImage: "bell")
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                    .navigationTitle("Preferences")
                    .listStyle(listStyle)
                } detail: {
                    switch viewModel.navigationSelection {
                    case .none:
                        Text("No selection")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 64)
                    case .selectLocation:
                        OverrideLocationView(locationManager: locationManager)
                            .navigationTitle("Select Location")
                    case .visibility:
                        VisiblePrayersView(visiblePrayers: $preferences.visiblePrayers)
                            .navigationTitle("Visibility")
                    case .calculationMethod:
                        CalculationMethodView(calculationMethod: $preferences.calculationMethod)
                            .navigationTitle("Calculation Method")
                    case .notification(let category):
                        UserNotificationSelectionView(category: category, selection: notificationCategoryBinding(category))
                            .navigationTitle(category.localizedTitle)
                    }
                }
            } else {
                NavigationView {
                    List {
                        if shouldShowLocationSection {
                            Section {
                                NavigationLink("Select Location", tag: .selectLocation, selection: $viewModel.navigationSelection) {
                                    OverrideLocationView(locationManager: locationManager)
                                        .navigationTitle("Select Location")
                                }
                            } header: {
                                Label("Location", systemImage: "location")
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                        
                        Section {
                            NavigationLink("Visibility", tag: .visibility, selection: $viewModel.navigationSelection) {
                                VisiblePrayersView(visiblePrayers: $preferences.visiblePrayers)
                                    .navigationTitle("Visibility")
                            }
                            NavigationLink("Calculation Method", tag: .calculationMethod, selection: $viewModel.navigationSelection) {
                                CalculationMethodView(calculationMethod: $preferences.calculationMethod)
                                    .navigationTitle("Calculation Method")
                            }
                        } header: {
                            Label("Configuration", systemImage: "gear")
                                .symbolRenderingMode(.multicolor)
                        }
                        
                        Section {
                            ForEach(UserNotification.Category.allCases) { category in
                                NavigationLink(category.localizedTitle, tag: .notification(category), selection: $viewModel.navigationSelection) {
                                    UserNotificationSelectionView(category: category, selection: notificationCategoryBinding(category))
                                        .navigationTitle(category.localizedTitle)
                                }
                            }
                        } header: {
                            Label("Notifications", systemImage: "bell")
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                    .navigationTitle("Preferences")
                    .listStyle(listStyle)
                    
                    Text("No selection")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 64)
                }
            }
        }
        .onChangeOf(shouldShowLocationSection) { shouldShowLocationSection in
            if !shouldShowLocationSection && viewModel.navigationSelection == .selectLocation {
                viewModel.navigationSelection = .none
            }
        }
    }
}

struct VisiblePrayersView: View {
    @Binding var visiblePrayers: Set<Prayer.Name>
    
    private let hiddenPrayers: [Prayer.Name] = [ .fajr, .dhuhr, .asr, .maghrib, .isha ]
    
    private var footerText: String {
        "Unselect items to hide them in the Times listing. This selection does not affect notifications.\n" + hiddenPrayers.map(\.localized).formatted(.list(type: .and)) + " are always shown."
    }
    
    var body: some View {
        List {
            Section {
                PrayerNameSelection(selection: $visiblePrayers, hidden: Set(hiddenPrayers))
            } footer: {
                Text(footerText)
            }
        }
    }
}

struct CalculationMethodView: View {
    @Binding var calculationMethod: CalculationMethod
    
    private var configurationBinding: Binding<CalculationParameters.Configuration> {
        Binding {
            calculationMethod.calculationConfiguration
        } set: { newValue in
            calculationMethod = .custom(newValue)
        }
    }
    
    private var calculationMethods: [CalculationMethod] {
        [
            .mwl,
            .isna,
            .egypt,
            .karachi,
            .indonesia,
            .custom(calculationMethod.calculationConfiguration)
        ]
    }
    
    var body: some View {
        List {
            ForEach(calculationMethods) { method in
                HStack {
                    Text(method.title)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .opacity(calculationMethod == method ? 1 : 0)
                }
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel(method.title)
                .accessibilityAddTraits((calculationMethod == method) ? [ .isSelected ] : [])
                .onTapGesture {
                    calculationMethod = method
                }
            }
            if case .custom = calculationMethod {
                CalculationConfigurationView(configuration: configurationBinding)
                    .padding(.leading, 16)
            }
        }
    }
}

struct CalculationConfigurationView: View {
    @Binding var configuration: CalculationParameters.Configuration
    
    var body: some View {
        FloatingRangeSelection("Asr Factor", value: $configuration.asrFactor, in: 1...2, step: 1)
        FloatingRangeSelection("Fajr Angle", value: $configuration.fajrAngle, in: 4...24, step: 0.5)
        FloatingRangeSelection("Isha Angle", value: $configuration.ishaAngle, in: 4...24, step: 0.5)
    }
}

struct FloatingRangeSelection<Value: BinaryFloatingPoint>: View {
    let title: String
    
    @Binding var value: Value
    
    let range: ClosedRange<Value>
    let step: Value.Stride
    
    init(_ title: String, value: Binding<Value>, in range: ClosedRange<Value>, step: Value.Stride) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(value.formatted())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value.formatted())
    }
}

struct UserNotificationSelectionView: View {
    let category: UserNotification.Category
    
    @Binding var selection: Set<Prayer.Name>
    
    var footerText: String {
        switch category {
        case .start:
            return "A notification will be sent at the start of the selected times."
        case .reminder:
            return "A notification will be sent 30 minutes before the start of the selected times."
        }
    }
    
    var body: some View {
        List {
            Section {
                PrayerNameSelection(selection: $selection)
            } footer: {
                Text(footerText)
            }
        }
    }
}

extension UserNotification.Category {
    var localizedTitle: String {
        switch self {
        case .start: return "Start"
        case .reminder: return "Reminder"
        }
    }
}

extension CalculationMethod {
    var title: String {
        switch self {
        case .mwl: return "Muslim World League (MWL)"
        case .isna: return "Islamic Society of North America (ISNA)"
        case .egypt: return "Egyptian General Authority of Survey"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .indonesia: return "Ministry of Religion Indonesia (KEMENAG)"
        case .custom: return "Custom"
        }
    }
}

extension CalculationMethod: @retroactive Identifiable {
    public var id: Self { self }
}

extension UserNotification.Category: @retroactive Identifiable {
    public var id: Self { self }
}

private extension View {
    @ViewBuilder
    func onChangeOf<T: Equatable>(_ value: T, perform block: @escaping (T) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            onChange(of: value) { oldValue, newValue in
                block(newValue)
            }
        } else {
            onChange(of: value, perform: block)
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(locationManager: .shared, preferences: .shared, viewModel: .init())
    }
}
