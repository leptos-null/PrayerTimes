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
            guard Self.calculationMethod(from: userDefaults) != calculationMethod else { return }
            logger.debug("Writing calculationMethod")
            
            userDefaults.setEncoded(value: calculationMethod, forKey: .calculationMethod)
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
    
    @Published public var visiblePrayers: Set<Prayer.Name> {
        didSet {
            guard Self.visiblePrayers(from: userDefaults) != visiblePrayers else { return }
            logger.debug("Writing visiblePrayers")
            
            userDefaults.setEncoded(value: visiblePrayers, forKey: .visiblePrayers)
        }
    }
    
    private static func calculationMethod(from userDefaults: UserDefaults) -> CalculationMethod {
        userDefaults.decodedValue(forKey: .calculationMethod) ?? .isna
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
    
    private static func visiblePrayers(from userDefaults: UserDefaults) -> Set<Prayer.Name> {
        userDefaults.decodedValue(forKey: .visiblePrayers) ?? [ .fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha ]
    }
    
    init() {
        guard let userDefaults = UserDefaults(suiteName: "group.null.leptos.PrayerTimesGroup") else { fatalError("Failed to get group user defaults") }
        self.userDefaults = userDefaults
        
        calculationMethod = Self.calculationMethod(from: userDefaults)
        userNotifications = Self.userNotificationPreferences(from: userDefaults)
        visiblePrayers = Self.visiblePrayers(from: userDefaults)
        
        observer.observe(object: userDefaults, forKeyPath: UserDefaultsKey.calculationMethod.stringValue) { [weak self] _ in
            guard let self = self else { return }
            
            let update = Self.calculationMethod(from: userDefaults)
            guard self.calculationMethod != update else { return }
            self.calculationMethod = update
        }
        
        UserDefaultsKey.allNotificationCases.forEach { key in
            observer.observe(object: userDefaults, forKeyPath: key.stringValue) { [weak self] _ in
                guard let self = self else { return }
                
                let update = Self.userNotificationPreferences(from: userDefaults)
                guard self.userNotifications != update else { return }
                self.userNotifications = update
            }
        }
        
        observer.observe(object: userDefaults, forKeyPath: UserDefaultsKey.visiblePrayers.stringValue) { [weak self] _ in
            guard let self = self else { return }
            
            let update = Self.visiblePrayers(from: userDefaults)
            guard self.visiblePrayers != update else { return }
            self.visiblePrayers = update
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
        
        case calculationMethod
        case visiblePrayers
        case notification(UserNotification.Category, Prayer.Name)
        
        public var stringValue: String {
            switch self {
            case .calculationMethod: return "PreferencesCalculationMethod"
            case .visiblePrayers: return "PreferencesVisiblePrayers"
            case .notification(let category, let name):
                return "PreferencesNotification_\(category)_\(name)"
            }
        }
    }
}

extension Preferences.UserDefaultsKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .calculationMethod: return "calculationMethod"
        case .visiblePrayers: return "visiblePrayers"
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
            Self.logger.error("Requested \(T.self) for \(key), found \(String(describing: object))")
            return nil
        }
        return value
    }
}

private extension UserDefaults {
    func set(_ value: Bool, forKey key: Preferences.UserDefaultsKey) {
        set(value, forKey: key.stringValue)
    }
    
    func set(_ value: Data, forKey key: Preferences.UserDefaultsKey) {
        set(value, forKey: key.stringValue)
    }
}

private extension UserDefaults {
    func setEncoded<T: Encodable>(value: T, forKey key: Preferences.UserDefaultsKey) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data: Data = try encoder.encode(value)
            set(data, forKey: key)
        } catch {
            Self.logger.error("PropertyListEncoder.encode(\(String(describing: value))): \(String(describing: error))")
            return
        }
    }
    
    func decodedValue<T: Decodable>(forKey key: Preferences.UserDefaultsKey) -> T? {
        guard let data: Data = value(forKey: key) else { return nil }
        let decoder = PropertyListDecoder()
        do {
            let value = try decoder.decode(T.self, from: data)
            return value
        } catch {
            Self.logger.error("PropertyListDecoder.decode(\(T.self), from: \(data)): \(String(describing: error))")
            return nil
        }
    }
}
