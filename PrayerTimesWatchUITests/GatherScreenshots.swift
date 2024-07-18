//
//  GatherScreenshots.swift
//  PrayerTimesWatchUITests
//
//  Created by Leptos on 4/17/22.
//

import XCTest

class GatherScreenshots: XCTestCase {
    private var directory: URL?
    private var paths: [String: String] = [:] // file name, description
    
    override func setUp() {
        continueAfterFailure = false
        
        let file = URL(fileURLWithPath: #file)
        let project = URL(fileURLWithPath: "..", isDirectory: true, relativeTo: file)
        
        let environment = ProcessInfo.processInfo.environment
        guard let model = environment["SIMULATOR_MODEL_IDENTIFIER"] else {
            fatalError("Screenshot collection should be run in the simulator")
        }
        
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
        
        let environment = ProcessInfo.processInfo.environment
        guard let deviceName = environment["SIMULATOR_DEVICE_NAME"] else {
            fatalError("SIMULATOR_DEVICE_NAME is not set")
        }
        guard let version = environment["SIMULATOR_RUNTIME_VERSION"] else {
            fatalError("SIMULATOR_RUNTIME_VERSION is not set")
        }
        readMe += "## \(deviceName) \(version)\n\n"
        
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
    
    // at the time of writing this (Xcode 13.3), watchOS does not support overriding the status bar time
    // if it did, the date would be "2021-09-14T17:09:30Z"
    
    func testGetScreenshots() {
#if !SCREENSHOT_MODE
        XCTAssert(false, "SCREENSHOT_MODE should be set to gather screenshot")
#endif
        let app = XCUIApplication()
        
        app.launch()
        
        // scroll bar takes some time to disappear
        sleep(1)
        write(screenshot: app.screenshot(), name: "0_today", description: "Today")
        
        let tabView = app.collectionViews.firstMatch
        
        tabView.swipeRight()
        write(screenshot: app.screenshot(), name: "1_qibla_compass", description: "Qibla Compass")
        
        tabView.swipeLeft()
        tabView.swipeLeft()
        write(screenshot: app.screenshot(), name: "2_preferences", description: "Preferences")
    }
}
