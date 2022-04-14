//
//  Preferences.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/1/22.
//

import Foundation
import os

public final class Preferences: ObservableObject {
    public static let shared = Preferences()
    
    private let userDefaults: UserDefaults
    private let observer = KeyValueObserver()
    
    private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "Preferences")
    
    @Published public var calculationMethod: CalculationMethod {
        didSet {
            updateUserDefaults(calculationMethod, for: .calculationMethod, read: Self.calculationMethod(from:))
        }
    }
    
    @Published public var userNotifications: UserNotification.Preferences {
        didSet {
            updateUserDefaults(userNotifications, for: .userNotifications, read: Self.userNotifications(from:))
        }
    }
    
    @Published public var visiblePrayers: Set<Prayer.Name> {
        didSet {
            updateUserDefaults(visiblePrayers, for: .visiblePrayers, read: Self.visiblePrayers(from:))
        }
    }
    
    private static func calculationMethod(from userDefaults: UserDefaults) -> CalculationMethod {
#if SCREENSHOT_MODE
        .isna
#else
        userDefaults.decodedValue(forKey: .calculationMethod) ?? .isna
#endif
    }
    
    private static func userNotifications(from userDefaults: UserDefaults) -> UserNotification.Preferences {
#if SCREENSHOT_MODE
        .init(categories: [
            .start: [ .fajr, .dhuhr, .asr, .maghrib, .isha ],
            .reminder: [ .sunrise, .maghrib, .isha ]
        ])
#else
        userDefaults.decodedValue(forKey: .userNotifications) ?? .init(categories: [:])
#endif
    }
    
    private static func visiblePrayers(from userDefaults: UserDefaults) -> Set<Prayer.Name> {
#if SCREENSHOT_MODE
        [ .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha ]
#else
        userDefaults.decodedValue(forKey: .visiblePrayers) ?? [ .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha ]
#endif
    }
    
    private func updateUserDefaults<T: Equatable>(_ value: T, for key: UserDefaultsKey, read: @escaping (UserDefaults) -> T) where T: Encodable {
        guard read(userDefaults) != value else { return }
        logger.debug("Writing \(String(describing: value)) for \(key)")
        
        userDefaults.setEncoded(value: value, forKey: key)
    }
    
    private func observeUserDefaults<T: Equatable>(for key: UserDefaultsKey, property: ReferenceWritableKeyPath<Preferences, T>, read: @escaping (UserDefaults) -> T) {
        observer.observe(object: userDefaults, forKeyPath: key.rawValue) { [weak self] _ in
            guard let self = self else { return }
            
            let update = read(self.userDefaults)
            guard self[keyPath: property] != update else { return }
            self[keyPath: property] = update
        }
    }
    
    init() {
        guard let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup") else { fatalError("Failed to get group user defaults") }
        self.userDefaults = userDefaults
        
        calculationMethod = Self.calculationMethod(from: userDefaults)
        userNotifications = Self.userNotifications(from: userDefaults)
        visiblePrayers = Self.visiblePrayers(from: userDefaults)
        
        observeUserDefaults(for: .calculationMethod, property: \.calculationMethod, read: Self.calculationMethod(from:))
        observeUserDefaults(for: .userNotifications, property: \.userNotifications, read: Self.userNotifications(from:))
        observeUserDefaults(for: .visiblePrayers,    property: \.visiblePrayers,    read: Self.visiblePrayers(from:))
    }
}

extension Preferences {
    enum UserDefaultsKey: String {
        case calculationMethod = "PreferencesCalculationMethod"
        case userNotifications = "PreferencesUserNotifications"
        case visiblePrayers = "PreferencesVisiblePrayers"
    }
}

extension Preferences.UserDefaultsKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .calculationMethod: return "calculationMethod"
        case .userNotifications: return "userNotifications"
        case .visiblePrayers: return "visiblePrayers"
        }
    }
}

private extension UserDefaults {
    func setEncoded<T: Encodable>(value: T, forKey key: Preferences.UserDefaultsKey) {
        do {
            try setEncoded(value: value, forKey: key.rawValue)
        } catch {
            Self.logger.error("setEncoded(value: \(String(describing: value)), forKey: \(key)): \(String(describing: error))")
            return
        }
    }
    
    func decodedValue<T: Decodable>(forKey key: Preferences.UserDefaultsKey) -> T? {
        do {
            return try decodedValue(forKey: key.rawValue)
        } catch {
            Self.logger.error("decodedValue(forKey: \(key)): \(String(describing: error))")
            return nil
        }
    }
}
