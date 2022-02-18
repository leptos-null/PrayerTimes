//
//  OrientationManager.swift
//  PrayerTimes
//
//  Created by Leptos on 2/17/22.
//

import Combine
import UIKit

final class OrientationManager: ObservableObject {
    @Published var orientation: UIDeviceOrientation
    
    let device: UIDevice
    
    init(device: UIDevice) {
        self.device = device
        orientation = device.orientation
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification, object: device)
            .compactMap { $0.object as? UIDevice }
            .map(\.orientation)
            .assign(to: &$orientation)
    }
    
    var isUpdatingOrientation: Bool {
        device.isGeneratingDeviceOrientationNotifications
    }
    
    func startUpdatingOrientation() {
        device.beginGeneratingDeviceOrientationNotifications()
    }
    
    func stopUpdatingOrientation() {
        device.endGeneratingDeviceOrientationNotifications()
    }
}
