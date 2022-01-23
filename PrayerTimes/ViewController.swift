//
//  ViewController.swift
//  PrayerTimes
//
//  Created by Leptos on 1/18/22.
//

import UIKit
import SwiftUI

class ViewController: UIHostingController<ContentView> {
    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: ContentView())
    }
}
