//
//  CLDeviceOrientation+UIKit.swift
//  PrayerTimes
//
//  Created by Leptos on 2/17/22.
//

import CoreLocation
import UIKit

extension CLDeviceOrientation {
    init(_ orientation: UIDeviceOrientation) {
        switch orientation {
        case .unknown:            self = .unknown
        case .portrait:           self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft:      self = .landscapeLeft
        case .landscapeRight:     self = .landscapeRight
        case .faceUp:             self = .faceUp
        case .faceDown:           self = .faceDown
        @unknown default:         self = .unknown // this case is mostly so we can be notified at compile time if a new case is added
        }
    }
}
