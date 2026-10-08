//
//  GatherScreenshots.swift
//  PrayerTimesUITests
//
//  Created by Leptos on 4/13/22.
//

import XCTest
import CoreImage.CIFilterBuiltins

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
    
    private func screenshotPngData(cornerRadius: Float, pngRepresentation: Data) -> Data {
        guard cornerRadius > 0 else { return pngRepresentation }
        
        guard let image = CIImage(data: pngRepresentation) else {
            fatalError("failed to decode screenshot")
        }
        
        let maskFilter = CIFilter.roundedRectangleGenerator()
        maskFilter.extent = image.extent
        maskFilter.radius = cornerRadius
        maskFilter.color = .white
        
        // per <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>
        // > **Note:** Images can’t include alpha channels or transparencies.
        //
        // use a gray background so the masked image isn't too big of a jump against either a white or black background
        let backgroundColor: CIColor = .init(red: 0.5, green: 0.5, blue: 0.5)
        let blendFilter = CIFilter.blendWithAlphaMask()
        blendFilter.inputImage = image
        blendFilter.backgroundImage = CIImage(color: backgroundColor).cropped(to: image.extent)
        blendFilter.maskImage = maskFilter.outputImage
        
        guard let outputImage = blendFilter.outputImage else {
            fatalError("failed to mask screenshot")
        }
        
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let ciContext = CIContext()
        guard let pngData = ciContext.pngRepresentation(of: outputImage, format: .RGBX8, colorSpace: colorSpace) else {
            fatalError("failed to encode screenshot")
        }
        return pngData
    }
    
    private func write(screenshot: XCUIScreenshot, name: String, description: String? = nil) {
        guard let directory = directory else {
            fatalError("directory is unset")
        }
        
        let cornerRadius: Float
#if targetEnvironment(macCatalyst)
        cornerRadius = if #available(macCatalyst 26.0, *) {
            50
        } else {
            12 // TODO: confirm
        }
#else
        cornerRadius = 0
#endif
        let pngData = screenshotPngData(cornerRadius: cornerRadius, pngRepresentation: screenshot.pngRepresentation)
        
        let path = directory.appendingPathComponent(name).appendingPathExtension("png")
        try! pngData.write(to: path, options: .atomic)
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
        
        let screenshotProvider: XCUIScreenshotProviding
#if os(iOS) && !targetEnvironment(macCatalyst)
        // observed on iPadOS 27.0, an app element's screenshot isn't rotated to match the display orientation
        screenshotProvider = XCUIScreen.main
#else
        screenshotProvider = window
#endif
        
        let tabBar: XCUIElement
#if os(visionOS)
        // on visionOS, the "tab bar" is in another window that doesn't have an identifier
        tabBar = window
#else
        // observed on iPadOS 27.0, there aren't any `tabBars` (on iOS 27.0, a tab bar is present)
        tabBar = if window.tabBars.count > 0 {
            window.tabBars.firstMatch
        } else if window.radioGroups.count > 0 {
            // observed on Mac Catalyst, the tabs are in the only match for `radioGroups`
            window.radioGroups.firstMatch
        } else {
            window
        }
#endif
        
        func selectTab(_ key: String) {
#if os(visionOS)
            // in my testing on visionOS, the hierarchy for "Qibla" looks like:
            //
            //   Button, {{17.5, 16.5}, {187.0, 44.0}}, label: 'Qibla' /* label */
            //     Button, {{33.0, 27.0}, {13.5, 23.5}}, label: 'orient to north' /* label icon */
            //     Button, {{65.5, 27.0}, {46.0, 23.0}}, label: 'Qibla' /* label title */
            //
            tabBar.buttons[key].firstMatch.tap()
#else
            // in my testing on iPadOS 27.0, the hierarchy for "Qibla" looks like:
            //
            //   Button, {{548.8, 36.0}, {72.5, 36.0}}, identifier: 'location.north.line', label: 'Qibla'
            //     Button, {{548.8, 36.0}, {72.5, 36.0}}, identifier: 'location.north.line', label: 'Qibla'
            //
            let itemButton = tabBar.buttons[key]
            if itemButton.isHittable {
                itemButton.tap()
            } else if itemButton.exists {
                itemButton.firstMatch.tap()
            } else {
                // for macCatalyst
                tabBar.radioButtons[key].tap()
            }
#endif
        }
        
        let timeTabView: XCUIElement = if #available(iOS 16.0, *) {
            window.collectionViews.firstMatch
        } else {
            window.scrollViews.firstMatch
        }
        
        // since the cursor (on macOS) is left hovering over the tab that was just selected,
        // the tabs appear "highlighted" in all the other screenshots.
        // for consistency, select the first tab too.
        selectTab("Times")
        
        write(screenshot: screenshotProvider.screenshot(), name: "0_today", description: "Today")
        timeTabView.swipeLeft()
        // skip tomorrow view, it has similar aspects to today and date scrubber
        timeTabView.swipeLeft()
        
        // for some reason, in my testing on iOS (and iPadOS) 27, the date picker on the scrub view
        // shows in the numerical format until we interact with the tab bar (then it switches to words).
        // flip the tabs back and forth to show it in the word format, which looks better, in my opinion.
        selectTab("Qibla")
        selectTab("Times")
        
        write(screenshot: screenshotProvider.screenshot(), name: "1_date_scrub", description: "Date Scrubber")
        
        selectTab("Qibla")
        
#if !(targetEnvironment(macCatalyst) || os(visionOS)) /* platforms without compass heading support */
        write(screenshot: screenshotProvider.screenshot(), name: "2_qibla_compass", description: "Qibla Compass")
        
        window.buttons["Map"].tap()
#endif
        sleep(2) // give the map time to load
        write(screenshot: screenshotProvider.screenshot(), name: "2_qibla_map", description: "Qibla Map")
        
        selectTab("Preferences")
        // since the Preferences tab has a sidebar (in some interface configurations),
        // the tabs may move. on devices with a pointer, the pointer may happen to be
        // hovering over another tab after the tabs move. select the Preferences
        // tab again so the tab highlight appears consistent with the other screenshots.
        selectTab("Preferences")
        
        write(screenshot: screenshotProvider.screenshot(), name: "3_preferences", description: "Preferences")
    }
}
