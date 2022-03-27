//
//  StapledLocation.swift
//  PrayerTimesKit
//
//  Created by Leptos on 3/6/22.
//

import Foundation
import CoreLocation

public struct StapledLocation: Equatable {
    public let placemark: CLPlacemark?
    public let location: CLLocation
}

extension StapledLocation: Codable {
    private enum CodingKeys: String, CodingKey {
        case placemark
        case location
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

extension KeyedEncodingContainer {
    mutating func encode<Object>(object: Object, forKey key: KeyedEncodingContainer<K>.Key) throws where Object: NSObject, Object: NSSecureCoding {
        let data: Data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        try encode(data, forKey: key)
    }
}

extension KeyedDecodingContainer {
    func decodeObject<Object>(forKey key: KeyedDecodingContainer<K>.Key) throws -> Object where Object: NSObject, Object: NSSecureCoding {
        let data = try decode(Data.self, forKey: key)
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)!
    }
    
    func decodeObjectIfPresent<Object>(forKey key: KeyedDecodingContainer<K>.Key) throws -> Object? where Object: NSObject, Object: NSSecureCoding {
        guard let data = try decodeIfPresent(Data.self, forKey: key) else { return nil }
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Object.self, from: data)!
    }
}
