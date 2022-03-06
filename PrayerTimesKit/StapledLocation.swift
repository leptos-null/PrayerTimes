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
    
    private let placemarkDictionaryRepresentationKey = "Placemark"
    private let locationDictionaryRepresentationKey = "Location"
    
    var dictionaryRepresentation: [String: Data] {
        get throws {
            var representation: [String: Data] = [:]
            
            if let placemark = placemark {
                let placemarkData = try NSKeyedArchiver.archivedData(withRootObject: placemark, requiringSecureCoding: true)
                representation[placemarkDictionaryRepresentationKey] = placemarkData
            }
            
            let locationData = try NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: true)
            representation[locationDictionaryRepresentationKey] = locationData
            
            return representation
        }
    }
    
    init(dictionaryRepresentation: [String: Data]) throws {
        guard let locationData = dictionaryRepresentation[locationDictionaryRepresentationKey] else {
            throw CocoaError(.coderValueNotFound)
        }
        if let placemarkData = dictionaryRepresentation[placemarkDictionaryRepresentationKey] {
            placemark = try NSKeyedUnarchiver.unarchivedObject(ofClass: CLPlacemark.self, from: placemarkData)!
        } else {
            placemark = nil
        }
        location = try NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: locationData)!
    }
    
    init(placemark: CLPlacemark?, location: CLLocation) {
        self.placemark = placemark
        self.location = location
    }
}
