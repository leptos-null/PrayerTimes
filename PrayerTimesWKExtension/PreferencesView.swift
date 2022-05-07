//
//  PreferencesView.swift
//  PrayerTimesWKExtension
//
//  Created by Leptos on 3/22/22.
//

import SwiftUI
import PrayerTimesUI
import PrayerTimesKit

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("Visibility") {
                        VisiblePrayersView(visiblePrayers: $preferences.visiblePrayers)
                            .navigationTitle("Visibility")
                    }
                    NavigationLink("Calculation Method") {
                        CalculationMethodView(calculationMethod: $preferences.calculationMethod)
                            .navigationTitle("Calculation Method")
                    }
                } header: {
                    Label("Configuration", systemImage: "gear")
                        .symbolRenderingMode(.multicolor)
                }
                
                Section {
                    UserNotificationPreferencesView(preferences: $preferences.userNotifications)
                        .navigationBarBackButtonHidden(false)
                } header: {
                    Label("Notifications", systemImage: "bell")
                        .symbolRenderingMode(.multicolor)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VisiblePrayersView: View {
    @Binding var visiblePrayers: Set<Prayer.Name>
    
    private let hiddenPrayers: [Prayer.Name] = [ .fajr, .dhuhr, .asr, .maghrib, .isha ]
    
    private var footerText: String {
        "Unselect items to hide them in the app and complications. This selection does not affect notifications.\n" + hiddenPrayers.map(\.localized).formatted(.list(type: .and)) + " are always shown."
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

struct FloatingRangeSelection<Value: BinaryFloatingPoint>: View where Value.Stride: BinaryFloatingPoint {
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
        NavigationLink {
            VStack {
                Slider(value: $value, in: range, step: step) {
                    Text(title)
                }
                Text(value.formatted())
                    .accessibilityHidden(true) // the Slider above is providing the value
            }
            .navigationTitle(title)
        } label: {
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

struct UserNotificationPreferencesView: View {
    @Binding var preferences: UserNotification.Preferences
    
    private func categoryBinding(_ category: UserNotification.Category) -> Binding<Set<Prayer.Name>> {
        Binding {
            preferences.categories[category] ?? Set()
        } set: {
            preferences.categories[category] = $0
        }
    }
    
    var body: some View {
        ForEach(UserNotification.Category.allCases) { category in
            NavigationLink(category.localizedTitle) {
                UserNotificationSelectionView(category: category, selection: categoryBinding(category))
                    .navigationTitle(category.localizedTitle)
            }
        }
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
        case .custom: return "Custom"
        }
    }
}

extension CalculationMethod: Identifiable {
    public var id: Self { self }
}

extension UserNotification.Category: Identifiable {
    public var id: Self { self }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(preferences: .shared)
    }
}
