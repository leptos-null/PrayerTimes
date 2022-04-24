//
//  StapledLocation.swift
//  PrayerTimesKit
//
//  Created by Leptos on 3/6/22.
//

import Foundation
import CoreLocation

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
public struct StapledLocation: Equatable {
    public let placemark: CLPlacemark?
    public let location: CLLocation
}

extension StapledLocation: Codable {
    private enum CodingKeys: String, CodingKey {
        case version
        case payload
    }
    
    private enum EncodingVersion: Int, Codable, CaseIterable {
        case v0
    }
    
    // Exact copy of properties at v0
    private struct V0: Codable {
        public let placemark: CLPlacemark?
        public let location: CLLocation
        
        private enum CodingKeys: String, CodingKey {
            case placemark
            case location
        }
        
        init(placemark: CLPlacemark?, location: CLLocation) {
            self.placemark = placemark
            self.location = location
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            placemark = try container.decodeObjectIfPresent(forKey: .placemark)
            location = try container.decodeObject(forKey: .location)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if let placemark = placemark {
                try container.encode(object: placemark, forKey: .placemark)
            }
            
            try container.encode(object: location, forKey: .location)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(EncodingVersion.self, forKey: .version)
        switch version {
        case .v0:
            let versioned: V0 = try container.decode(V0.self, forKey: .payload)
            self.init(placemark: versioned.placemark, location: versioned.location)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let latest = V0(placemark: placemark, location: location)
        
        try container.encode(EncodingVersion.v0, forKey: .version)
        try container.encode(latest, forKey: .payload)
    }
}

extension KeyedEncodingContainer {
    mutating func encode<Object>(object: Object, forKey key: Key) throws where Object: NSObject, Object: NSSecureCoding {
        let data: Data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        try encode(data, forKey: key)
    }
}

extension KeyedDecodingContainer {
    func decodeObject<Object>(forKey key: Key) throws -> Object where Object: NSObject, Object: NSSecureCoding {
        let data = try decode(Data.self, forKey: key)
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)!
    }
    
    func decodeObjectIfPresent<Object>(forKey key: Key) throws -> Object? where Object: NSObject, Object: NSSecureCoding {
        guard let data = try decodeIfPresent(Data.self, forKey: key) else { return nil }
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)!
    }
}
