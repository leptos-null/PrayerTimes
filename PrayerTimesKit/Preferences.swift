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
    
    @Published public var calculationParameters: CalculationParameters.Configuration {
        didSet {
            guard Self.calculationConfiguration(from: userDefaults) != calculationParameters else { return }
            logger.debug("Writing calculationParameters")
            
            userDefaults.set(calculationParameters.asrFactor, forKey: .asrFactor)
            userDefaults.set(calculationParameters.fajrAngle, forKey: .fajrAngle)
            userDefaults.set(calculationParameters.ishaAngle, forKey: .ishaAngle)
        }
    }
    
    @Published public var userNotifications: UserNotification.Preferences {
        didSet {
            guard Self.userNotificationPreferences(from: userDefaults) != userNotifications else { return }
            logger.debug("Writing userNotifications")
            
            UserDefaultsKey.allNotificationCases.forEach { key in
                guard case .notification(let category, let name) = key else { return }
                userDefaults.set(userNotifications.enabledFor(category: category, name: name), forKey: key)
            }
        }
    }
    
    private static func calculationConfiguration(from userDefaults: UserDefaults) -> CalculationParameters.Configuration {
        CalculationParameters.Configuration(
            asrFactor: userDefaults.value(forKey: .asrFactor) ?? 1,
            fajrAngle: userDefaults.value(forKey: .fajrAngle) ?? 15,
            ishaAngle: userDefaults.value(forKey: .ishaAngle) ?? 15
        )
    }
    
    private static func userNotificationPreferences(from userDefaults: UserDefaults) -> UserNotification.Preferences {
        let categories: [UserNotification.Category: Set<Prayer.Name>] = UserNotification.Category.allCases.reduce(into: [:]) { partialResult, category in
            let names = Prayer.Name.allCases.filter {
                userDefaults.bool(forKey: .notification(category, $0))
            }
            partialResult[category] = Set(names)
        }
        return UserNotification.Preferences(categories: categories)
    }
    
    init() {
        guard let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup") else { fatalError("Failed to get group user defaults") }
        self.userDefaults = userDefaults
        
        calculationParameters = Self.calculationConfiguration(from: userDefaults)
        userNotifications = Self.userNotificationPreferences(from: userDefaults)
        
        let configurationKeys: [UserDefaultsKey] = [ .asrFactor, .fajrAngle, .ishaAngle ]
        configurationKeys.forEach { key in
            observer.observe(object: userDefaults, forKeyPath: key.stringValue) { [weak self] _ in
                guard let self = self else { return }
                
                let update = Self.calculationConfiguration(from: userDefaults)
                guard self.calculationParameters != update else { return }
                self.calculationParameters = update
            }
        }
        
        UserDefaultsKey.allNotificationCases.forEach { key in
            observer.observe(object: userDefaults, forKeyPath: key.stringValue) { [weak self] _ in
                guard let self = self else { return }
                
                let update = Self.userNotificationPreferences(from: userDefaults)
                guard self.userNotifications != update else { return }
                self.userNotifications = update
            }
        }
    }
}

public extension Preferences {
    enum UserDefaultsKey {
        static var allNotificationCases: [UserDefaultsKey] {
            UserNotification.Category.allCases.flatMap { category in
                Prayer.Name.allCases.map { name in
                    UserDefaultsKey.notification(category, name)
                }
            }
        }
        
        case asrFactor
        case fajrAngle
        case ishaAngle
        case notification(UserNotification.Category, Prayer.Name)
        
        public var stringValue: String {
            switch self {
            case .asrFactor: return "PreferencesAsrFactor"
            case .fajrAngle: return "PreferencesFajrAngle"
            case .ishaAngle: return "PreferencesIshaAngle"
            case .notification(let category, let name):
                return "PreferencesNotification_\(category)_\(name)"
            }
        }
    }
}

extension Preferences.UserDefaultsKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .asrFactor: return "asrFactor"
        case .fajrAngle: return "fajrAngle"
        case .ishaAngle: return "ishaAngle"
        case .notification(let category, let name):
            return "notification(\(category), \(name))"
        }
    }
}

private extension UserDefaults {
    private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "UserDefaults")
    
    func bool(forKey key: Preferences.UserDefaultsKey) -> Bool {
        bool(forKey: key.stringValue)
    }
    
    func value<T>(forKey key: Preferences.UserDefaultsKey) -> T? {
        guard let object = object(forKey: key.stringValue) else { return nil }
        guard let value = object as? T else {
            Self.logger.error("Requested \(String(describing: T.self)) for \(key), found \(String(describing: object))")
            return nil
        }
        return value
    }
}

private extension UserDefaults {
    func set(_ value: Bool, forKey key: Preferences.UserDefaultsKey) {
        set(value, forKey: key.stringValue)
    }
    
    func set(_ value: Double, forKey key: Preferences.UserDefaultsKey) {
        set(value, forKey: key.stringValue)
    }
}
