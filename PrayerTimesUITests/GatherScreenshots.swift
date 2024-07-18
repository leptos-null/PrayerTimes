//
//  GatherScreenshots.swift
//  PrayerTimesUITests
//
//  Created by Leptos on 4/13/22.
//

import XCTest

class GatherScreenshots: XCTestCase {
    private var directory: URL?
    private var paths: [String: String] = [:] // file name, description
    
    override func setUp() {
        continueAfterFailure = false
        
        let file = URL(fileURLWithPath: #file)
        let project = URL(fileURLWithPath: "..", isDirectory: true, relativeTo: file)
        
#if targetEnvironment(macCatalyst)
        let model = "macOS"
#else
        let environment = ProcessInfo.processInfo.environment
        guard let model = environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Screenshot collection should be run in the simulator")
        }
#endif
        
        let directory = project
            .appendingPathComponent("docs")
            .appendingPathComponent("Screenshots")
            .appendingPathComponent(model)
        
        let fileManager: FileManager = .default
        
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            assert(isDirectory.boolValue, "\(directory.path) should be a directory")
        } else {
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        self.directory = directory
    }
    
    override func tearDown() {
        var readMe: String = ""
        
#if targetEnvironment(macCatalyst)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        readMe += "## macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)\n\n"
#else
        let environment = ProcessInfo.processInfo.environment
        guard let deviceName = environment["SIMULATOR_DEVICE_NAME"] else {
            fatalError("SIMULATOR_DEVICE_NAME is not set")
        }
        guard let version = environment["SIMULATOR_RUNTIME_VERSION"] else {
            fatalError("SIMULATOR_RUNTIME_VERSION is not set")
        }
        readMe += "## \(deviceName) \(version)\n\n"
#endif
        
        paths
            .sorted { lhs, rhs in
                lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
            }
            .forEach { pair in
                readMe += "![\(pair.value)](\(pair.key))\n\n"
            }
        
        guard let directory = directory else {
            fatalError("directory is unset")
        }
        
        let fileName = directory.appendingPathComponent("README.md")
        try! readMe.write(to: fileName, atomically: true, encoding: .ascii)
    }
    
    private func write(screenshot: XCUIScreenshot, name: String, description: String? = nil) {
        guard let directory = directory else {
            fatalError("directory is unset")
        }
        
        let path = directory.appendingPathComponent(name).appendingPathExtension("png")
        try! screenshot.pngRepresentation.write(to: path, options: .atomic)
        paths[path.lastPathComponent] = (description ?? name)
    }
    
    /*
     influenced by https://github.com/jessesquires/Nine41
     
     $ xcrun simctl list | grep Booted # find booted devices
     run the following for the device you'll be gathering screenshots on:
     
     xcrun simctl status_bar <device> override \
     --time "2023-09-12T16:41:30.000Z" \
     --dataNetwork "wifi" --wifiMode "active" --wifiBars 3 \
     --cellularMode active --cellularBars 4 --operatorName " " \
     --batteryState charged --batteryLevel 100
     */
    private func statusBarOverrideCommand() -> String {
        let environment = ProcessInfo.processInfo.environment
        guard let deviceUDID = environment["SIMULATOR_UDID"] else {
            fatalError("SIMULATOR_UDID is not set")
        }
        return
"""
xcrun simctl status_bar \(deviceUDID) override \
--time "2023-09-12T16:41:30.000Z" \
--dataNetwork "wifi" --wifiMode "active" --wifiBars 3 \
--cellularMode active --cellularBars 4 --operatorName " " \
--batteryState charged --batteryLevel 100
"""
    }
    
    func testGetScreenshots() {
#if !SCREENSHOT_MODE
        XCTAssert(false, "SCREENSHOT_MODE should be set to gather screenshot")
#endif
        let app = XCUIApplication()
        
        app.launch()
        
#if targetEnvironment(macCatalyst)
        sleep(1) // window isn't available immediately, seemingly
        let window: XCUIElement = app.windows["SceneWindow"]
#else
        let window: XCUIElement = app
#endif
        
        // I'm not sure if this changed in iOS 16 or 17
        let timeTabView: XCUIElement = if #available(iOS 17.0, *) {
            window.collectionViews.firstMatch
        } else {
            window.scrollViews.firstMatch
        }
        
        write(screenshot: window.screenshot(), name: "0_today", description: "Today")
        timeTabView.swipeLeft()
        // skip tomorrow view, it has similar aspects to today and date scrubber
        timeTabView.swipeLeft()
        write(screenshot: window.screenshot(), name: "1_date_scrub", description: "Date Scrubber")
        
#if os(visionOS)
        // on visionOS, the "tab bar" is in another window that doesn't have an identifier
        let tabBar = window
#else
        let tabBar = window.tabBars.firstMatch
#endif
        
#if os(visionOS)
        // on visionOS, you get a hierachy that looks like:
        //
        //   Button, {{17.5, 16.5}, {187.0, 44.0}}, label: 'Qibla' /* label */
        //     Button, {{33.0, 27.0}, {13.5, 23.5}}, label: 'orient to north' /* label icon */
        //     Button, {{65.5, 27.0}, {46.0, 23.0}}, label: 'Qibla' /* label title */
        //
        tabBar.buttons["Qibla"].firstMatch.tap()
#else
        tabBar.buttons["Qibla"].tap()
#endif
#if !(targetEnvironment(macCatalyst) || os(visionOS)) /* platforms without compass heading support */
        write(screenshot: window.screenshot(), name: "2_qibla_compass", description: "Qibla Compass")
        
        window.buttons["Map"].tap()
#endif
        sleep(2) // give the map time to load
        write(screenshot: window.screenshot(), name: "2_qibla_map", description: "Qibla Map")
#if os(visionOS)
        // see tabBar usage above
        tabBar.buttons["Preferences"].firstMatch.tap()
#else
        tabBar.buttons["Preferences"].tap()
#endif
        
        write(screenshot: window.screenshot(), name: "3_preferences", description: "Preferences")
    }
}
