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
     --time "2021-09-14T16:41:00Z" \
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
--time "2021-09-14T16:41:00Z" \
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
        
        write(screenshot: window.screenshot(), name: "0_today", description: "Today")
        window.scrollViews.firstMatch.swipeLeft()
        // skip tomorrow view, it has similar aspects to today and date scrubber
        window.scrollViews.firstMatch.swipeLeft()
        write(screenshot: window.screenshot(), name: "1_date_scrub", description: "Date Scrubber")
        
        let tabBar = window.tabBars.firstMatch
        
        tabBar.buttons["Quibla"].tap()
#if !targetEnvironment(macCatalyst)
        write(screenshot: window.screenshot(), name: "2_quibla_compass", description: "Quibla Compass")
        
        window.buttons["Map"].tap()
#endif
        sleep(2) // give the map time to load
        write(screenshot: window.screenshot(), name: "2_quibla_map", description: "Quibla Map")
        
        tabBar.buttons["Preferences"].tap()
        
        write(screenshot: window.screenshot(), name: "3_preferences", description: "Preferences")
    }
}
