//
//  UserNotification.swift
//  PrayerTimesKit
//
//  Created by Leptos on 1/29/22.
//

import Foundation
import UserNotifications
import CoreLocation

public enum UserNotification {
    public static func registerFor(location: CLLocation, timezone: TimeZone, config: CalculationConfiguration, preferences: Preferences) async throws {
        let userNotificationCenter: UNUserNotificationCenter = .current()
        userNotificationCenter.removeAllPendingNotificationRequests()
        
        guard !preferences.isEmpty else { return }
        // start this off early, so we can begin doing calculations below
        async let isAuthorized = userNotificationCenter.requestAuthorization(options: [ .alert, .providesAppNotificationSettings ])
        
        let date: Date = .now
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timezone
        
        let notificationRequests: [UNNotificationRequest] = PrayerIterator(start: date, timezone: timezone, location: location, configuration: config)
            .lazy
            .flatMap { preferences.descriptors(for: $0) }
            .drop { date.timeIntervalSince($0.time) > 0 } // drop any notifications that are in the past
            .prefix(64) // testing on iOS 15 indicates that only 64 notifications can be registered at a time
            .map { notificationDescriptor in
                let dateComponents = gregorianCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationDescriptor.time)
                
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = notificationDescriptor.title
                // TODO: add location text in body
                
                let dateMatch = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                guard let year = dateComponents.year,
                      let month = dateComponents.month,
                      let day = dateComponents.day else { fatalError("[year, month, day] requested, however at least 1 is missing") }
                let identifier = "prayer-\(notificationDescriptor.category)-\(notificationDescriptor.prayer.name)-\(year)-\(month)-\(day)"
                
                return UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: dateMatch)
            }
        
        guard try await isAuthorized else { return }
        notificationRequests.forEach { notificationRequest in
            // TODO: Check for errors
            userNotificationCenter.add(notificationRequest)
        }
    }
}

public extension UserNotification {
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

public extension UserNotification {
    enum Category: Hashable, Codable, CaseIterable {
        case start, warn
    }
    
    struct Descriptor {
        static let warnInterval: TimeInterval = 30 * .minute
        
        let prayer: Prayer
        let category: Category
        
        var time: Date {
            switch category {
            case .start: return prayer.start
            case .warn: return prayer.start.addingTimeInterval(-Self.warnInterval)
            }
        }
        
        var title: String {
            switch category {
            case .start: return "Time for \(prayer.name.localized) has begun"
            case .warn: return "\(prayer.name.localized) begins in 30 minutes"
            }
        }
    }
}
