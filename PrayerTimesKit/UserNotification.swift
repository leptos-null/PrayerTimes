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
            // TODO: Check for errors
            userNotificationCenter.add(notificationRequest)
        }
    }
#endif
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
    enum Category: Hashable, CaseIterable {
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
