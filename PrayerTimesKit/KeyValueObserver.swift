//
//  KeyValueObserver.swift
//  PrayerTimesKit
//
//  Created by Leptos on 2/2/22.
//

import Foundation
import os

final class KeyValueObserver: NSObject {
    typealias ExplicitCallback = ([NSKeyValueChangeKey: Any]) -> Void
    typealias DefaultCallback = (String, NSObject, [NSKeyValueChangeKey: Any]) -> Void
    
    private struct Registration: Hashable {
        weak var object: NSObject?
        let keyPath: String
        let callback: ExplicitCallback?
        let context: UnsafeMutableRawPointer
        
        static func == (lhs: KeyValueObserver.Registration, rhs: KeyValueObserver.Registration) -> Bool {
            (lhs.object === rhs.object) && (lhs.keyPath == rhs.keyPath) && (lhs.context == rhs.context)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(keyPath)
            hasher.combine(context)
        }
    }
    
    static private let logger = Logger(subsystem: "null.leptos.PrayerTimesKit", category: "KeyValueObserver")
    
    private var registrations: Set<Registration> = Set()
    private let defaultHandler: DefaultCallback?
    
    init(defaultHandler: DefaultCallback? = nil) {
        self.defaultHandler = defaultHandler
    }
    
    func observe(object: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], callback: ExplicitCallback? = nil) {
        let alignment = UInt(MemoryLayout<UnsafeMutableRawPointer.Pointee>.alignment)
        let scaledMin: UInt = .min/alignment
        let scaledMax: UInt = .max/alignment
        let context = UnsafeMutableRawPointer(bitPattern: .random(in: scaledMin...scaledMax) * alignment)!
        
        object.addObserver(self, forKeyPath: keyPath, options: options, context: context)
        registrations.insert(Registration(object: object, keyPath: keyPath, callback: callback, context: context))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath,
              let object = object as? NSObject else {
                  Self.logger.notice("observeValue(forKeyPath: \(String(describing: keyPath)), of: \(String(describing: object)), change: \(String(describing: change)))")
                  return
              }
        
        registrations
            .filter { registration in
                registration.object === object && registration.keyPath == keyPath && registration.context == context
            }
            .forEach { registration in
                if let callback = registration.callback {
                    callback(change ?? [:])
                } else if let handler = defaultHandler {
                    handler(keyPath, object, change ?? [:])
                } else {
                    Self.logger.warning("valueDidChange for \(keyPath), and no callbacks found")
                }
            }
    }
    
    deinit {
        registrations.forEach { registration in
            registration.object?.removeObserver(self, forKeyPath: registration.keyPath, context: registration.context)
        }
    }
}
