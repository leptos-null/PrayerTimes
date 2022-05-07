//
//  UserNotification.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/29/22.
//

import Foundation
import UserNotifications
import CoreLocation
import os

public enum UserNotification {
    private static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "UserNotification")
    
#if os(iOS) || os(macOS) || os(watchOS)
    public static func registerFor(calculationParameters: CalculationParameters, preferences: Preferences, bodyText: String) async throws {
        let userNotificationCenter: UNUserNotificationCenter = .current()
        userNotificationCenter.removeAllPendingNotificationRequests()
        
        guard !preferences.isEmpty else { return }
        // start this off early, so we can begin doing calculations below
        async let isAuthorized = userNotificationCenter.requestAuthorization(options: [ .alert, .providesAppNotificationSettings ])
        
        let date: Date = .now
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = calculationParameters.timeZone
        
        let notificationRequests: [UNNotificationRequest] = PrayerIterator(start: date, calculationParameters: calculationParameters)
            .lazy
            .flatMap { preferences.descriptors(for: $0) }
            .drop { date.timeIntervalSince($0.time) > 0 } // drop any notifications that are in the past
            .prefix(64) // testing on iOS 15 indicates that only 64 notifications can be registered at a time
            .map { notificationDescriptor in
                let dateComponents = gregorianCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationDescriptor.time)
                
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = notificationDescriptor.title
                notificationContent.body = bodyText
                
                let dateMatch = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                guard let year = dateComponents.year,
                      let month = dateComponents.month,
                      let day = dateComponents.day else { fatalError("[year, month, day] requested, however at least 1 is missing") }
                let identifier = "prayer-\(notificationDescriptor.category)-\(notificationDescriptor.prayer.name)-\(year)-\(month)-\(day)"
                
                return UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: dateMatch)
            }
        
        guard try await isAuthorized else { return }
        notificationRequests.forEach { notificationRequest in
            userNotificationCenter.add(notificationRequest) { error in
                guard let error = error else { return }
                Self.logger.error("userNotificationCenter.add(\(notificationRequest)): \(error as NSError)")
            }
        }
    }
#endif
}

public extension UserNotification {
    // This structure is serialized and stored in UserDefaults.
    // For this reason, any changes to the declared properties should
    // be accompanied by a new version in the extension below.
    // A new version entails the following:
    //   assume the current version is `c`, and the new version we're adding is `n`
    //   n = c + 1
    //   Add `vn` as a case to `EncodingVersion`
    //   Create a private struct below `Vc` called Vn that has all the properties that Preferences now has
    //   Update the switch in init(from:) to handle `vn`
    //   Update encode(to:) such that `latest` is of type `Vn` and `vn` is encoded for `.version`
    struct Preferences: Hashable {
        public var categories: [Category: Set<Prayer.Name>]
        
        func descriptors(for prayer: Prayer) -> [Descriptor] {
            categories.compactMap { (category: Category, names: Set<Prayer.Name>) in
                guard names.contains(prayer.name) else { return nil }
                return Descriptor(prayer: prayer, category: category)
            }
        }
        
        var isEmpty: Bool {
            categories.allSatisfy { (category: Category, names: Set<Prayer.Name>) in
                names.isEmpty
            }
        }
        
        func enabledFor(category: Category, name: Prayer.Name) -> Bool {
            guard let names = categories[category] else { return false }
            return names.contains(name)
        }
        
        public init(categories: [Category: Set<Prayer.Name>]) {
            self.categories = categories
        }
    }
}

extension UserNotification.Preferences: Codable {
    private enum CodingKeys: String, CodingKey {
        case version
        case payload
    }
    
    private enum EncodingVersion: Int, Codable, CaseIterable {
        case v0
    }
    
    // Exact copy of properties at v0
    private struct V0: Codable {
        var categories: [UserNotification.Category: Set<Prayer.Name>]
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(EncodingVersion.self, forKey: .version)
        switch version {
        case .v0:
            let versioned: V0 = try container.decode(V0.self, forKey: .payload)
            self.init(categories: versioned.categories)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let latest = V0(categories: categories)
        
        try container.encode(EncodingVersion.v0, forKey: .version)
        try container.encode(latest, forKey: .payload)
    }
}

public extension UserNotification {
    // This enum is involved in serialization.
    // For this reason, in has certain stability requirements.
    //  - case names may not be renamed or remove
    //  - this type may not conform to RawRepresentable
    enum Category: Hashable, Codable, CaseIterable {
        case start, reminder
    }
    
    struct Descriptor {
        static let warnInterval: TimeInterval = 30 * .minute
        
        let prayer: Prayer
        let category: Category
        
        var time: Date {
            switch category {
            case .start: return prayer.start
            case .reminder: return prayer.start.addingTimeInterval(-Self.warnInterval)
            }
        }
        
        var title: String {
            switch category {
            case .start: return "Time for \(prayer.name.localized) has begun"
            case .reminder: return "\(prayer.name.localized) begins in 30 minutes"
            }
        }
    }
}

#if os(iOS) || os(macOS)

public extension UserNotification {
    final class Manager: ObservableObject {
        public static let current = Manager()
        
        private let center: UNUserNotificationCenter
        private let delegate = Delegate()
        
        @Published public private(set) var hasOpenSettingsRequest: Bool = false
        
        init(center: UNUserNotificationCenter = .current())  {
            self.center = center
            delegate.manager = self
        }
        /// - Note: `configure` must be called before the app finishes launching
        public func configure() {
            center.delegate = delegate
        }
        
        public func fulfillOpenSettingsRequest() {
            hasOpenSettingsRequest = false
        }
    }
}

extension UserNotification.Manager {
    final class Delegate: NSObject, UNUserNotificationCenterDelegate {
        private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "UserNotification.Manager.Delegate")
        
        weak var manager: UserNotification.Manager?
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
            guard let manager = manager else {
                logger.notice("\(#function) called while manager is nil")
                return
            }
            logger.debug("openSettingsFor(\(String(describing: notification)))")
            manager.hasOpenSettingsRequest = true
        }
    }
}

#endif
