//
//  UserDefaults+Typed.swift
//  PrayerTimesKit
//
//  Created by Leptos on 3/24/22.
//

import Foundation
import os

extension UserDefaults {
    static let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "UserDefaults")
    
    func value<T>(forKey key: String) -> T? {
        guard let object = object(forKey: key) else { return nil }
        guard let value = object as? T else {
            Self.logger.error("Requested \(T.self) for \(key), found \(String(describing: object))")
            return nil
        }
        return value
    }
}

extension UserDefaults {
    func setArchived<Object>(object: Object, forKey key: String) throws where Object: NSObject, Object: NSSecureCoding {
        let data: Data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        set(data, forKey: key)
    }
    
    func unarchivedObject<Object>(forKey key: String) throws -> Object? where Object: NSObject, Object: NSSecureCoding {
        guard let data: Data = value(forKey: key) else { return nil }
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)
    }
}

extension UserDefaults {
    func setEncoded<T: Encodable>(value: T, forKey key: String) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data = try encoder.encode(value)
        set(data, forKey: key)
    }
    
    func decodedValue<T: Decodable>(forKey key: String) throws -> T? {
        guard let data: Data = value(forKey: key) else { return nil }
        let decoder = PropertyListDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
