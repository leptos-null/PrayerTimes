//
//  PreferencesView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/2/22.
//

import SwiftUI
import PrayerTimesKit

public struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    
    public init(preferences: Preferences) {
        self.preferences = preferences
    }
    
    public var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    UserNotificationPreferencesView(preferences: $preferences.userNotifications)
                }
                Section("Configuration") {
                    CalculationConfigurationView(configuration: $preferences.calculationParameters)
                }
            }
            .navigationTitle("Preferences")
        }
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
                    .navigationTitle("Notifications")
            }
        }
    }
}

struct CalculationConfigurationView: View {
    @Binding var configuration: CalculationConfiguration
    
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
    }
}

struct UserNotificationSelectionView: View {
    let category: UserNotification.Category
    
    @Binding var selection: Set<Prayer.Name>
    
    var headerText: String {
        return category.localizedTitle
    }
    
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
            } header: {
                Text(headerText)
            } footer: {
                Text(footerText)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct PrayerNameSelection: View {
    @Binding var selection: Set<Prayer.Name>
    
    var body: some View {
        ForEach(Prayer.Name.allCases) { name in
            HStack {
                Text(name.localized)
                Spacer()
                Image(systemName: "checkmark")
                    .opacity(selection.contains(name) ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // if name is in selection, remove it, otherwise insert
                if selection.remove(name) == nil {
                    selection.insert(name)
                }
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

extension UserNotification.Category: Identifiable {
    public var id: Self { self }
}

extension Prayer.Name: Identifiable {
    public var id: Self { self }
}
