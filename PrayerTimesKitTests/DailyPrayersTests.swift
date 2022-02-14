//
//  DailyPrayersTests.swift
//  PrayerTimesKitTests
//
//  Created by Leptos on 1/23/22.
//

import XCTest
import CoreLocation
@testable import PrayerTimesKit

// https://www.islamicfinder.org/prayer-times can provide additional reference values

typealias HourMinute = (hour: Int, minute: Int)
typealias HourMinuteSecond = (hour: Int, minute: Int, second: Int)

class DailyPrayersTests: XCTestCase {
    
    struct ExpectedValues {
        let solarNoon: HourMinuteSecond
        let sunrise: HourMinute
        let sunset: HourMinute
        
        let fajr: HourMinuteSecond
        let asr: HourMinuteSecond
        let isha: HourMinuteSecond
        
        func validateDay(dateComponents: DateComponents, location: CLLocation, configuration: CalculationConfiguration) {
            guard let timeZone = dateComponents.timeZone else { fatalError() }
            // values for any time in the day should be the same
            (0..<24).forEach { hour in
                var componentsCopy = dateComponents
                componentsCopy.hour = hour
                componentsCopy.minute = hour
                componentsCopy.second = hour
                
                let daily = DailyPrayers(day: componentsCopy.date!, timeZone: timeZone, location: location, configuration: configuration)
                
                // based on https://gml.noaa.gov/grad/solcalc/
                // relatively high tolerance on these values, because of the lack of seconds
                //   and these values should not change, regardless of implementation
                XCTAssert(daily.dhuhr.start.timeBetween(dateComponents, solarNoon) < 60)
                XCTAssert(daily.sunrise.start.timeBetween(dateComponents, sunrise) < 120)
                XCTAssert(daily.maghrib.start.timeBetween(dateComponents, sunset) < 120)
                
                // based on previous calculations
                // as the implementation is updated, these values may be updated
                // i.e. the purpose of these tests are to let us know if a change
                //   inadvertently results in different output
                //   (as opposed to these tests strictly representing the desired output)
                XCTAssert(daily.fajr.start.timeBetween(dateComponents, fajr) < 2)
                XCTAssert(daily.asr.start.timeBetween(dateComponents, asr) < 2)
                XCTAssert(daily.isha.start.timeBetween(dateComponents, isha) < 2)
                
                // ensure isha is after maghrib, maghrib is after asr, etc.
                XCTAssert(daily.isha.start.timeIntervalSince(daily.maghrib.start) > 0)
                XCTAssert(daily.maghrib.start.timeIntervalSince(daily.asr.start) > 0)
                XCTAssert(daily.asr.start.timeIntervalSince(daily.dhuhr.start) > 0)
                XCTAssert(daily.dhuhr.start.timeIntervalSince(daily.sunrise.start) > 0)
                XCTAssert(daily.sunrise.start.timeIntervalSince(daily.fajr.start) > 0)
                XCTAssert(daily.fajr.start.timeIntervalSince(daily.qiyam.start) > 0)
                
                // failure cases to make sure logic is working
                XCTAssertFalse(daily.fajr.start.timeBetween(dateComponents, (12, 00)) < 200)
                XCTAssertFalse(daily.dhuhr.start.timeBetween(dateComponents, (18, 00)) < 200)
                XCTAssertFalse(daily.isha.start.timeBetween(dateComponents, (04, 00)) < 200)
                
                XCTAssertFalse(daily.asr.start.timeIntervalSince(daily.maghrib.start) > 0)
                XCTAssertFalse(daily.fajr.start.timeIntervalSince(daily.isha.start) > 0)
            }
        }
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNorthEast() {
        let location = CLLocation(latitude: 21.422495, longitude: 39.826158)
        let timeZone = TimeZone(identifier: "Asia/Riyadh")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18.5, ishaAngle: 19)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone)
        
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let janExpected = ExpectedValues(
            solarNoon: (12, 32, 30),
            sunrise: (07, 01),
            sunset:  (18, 05),
            fajr: (05, 40, 57),
            asr:  (15, 41, 23),
            isha: (19, 25, 30)
        )
        
        janExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 11
        dateComponents.day = 21
        
        let novExpected = ExpectedValues(
            solarNoon: (12, 06, 30),
            sunrise: (06, 35),
            sunset:  (17, 38),
            fajr: (05, 14, 53),
            asr:  (15, 15, 34),
            isha: (18, 59, 41)
        )
        
        novExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
    }
    
    func testNorthWest() {
        let location = CLLocation(latitude: 37.334900, longitude: -122.009020)
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 15, ishaAngle: 15)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let janExpected = ExpectedValues(
            solarNoon: (12, 19, 58),
            sunrise: (07, 17),
            sunset:  (17, 23),
            fajr: (06, 02, 28),
            asr:  (15, 01, 42),
            isha: (18, 36, 59)
        )
        
        janExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
        
        // day of time change
        dateComponents.year = 2022
        dateComponents.month = 3
        dateComponents.day = 13
        
        let marExpected = ExpectedValues(
            solarNoon: (13, 17, 23),
            sunrise: (07, 22),
            sunset:  (19, 14),
            fajr: (06, 11, 13),
            asr:  (16, 38, 43),
            isha: (20, 24, 03)
        )
        
        marExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
        
        // day of time change
        dateComponents.year = 2022
        dateComponents.month = 11
        dateComponents.day = 6
        
        let novExpected = ExpectedValues(
            solarNoon: (11, 51, 38),
            sunrise: (06, 38),
            sunset:  (17, 05),
            fajr: (05, 23, 48),
            asr:  (14, 43, 35),
            isha: (18, 19, 28)
        )
        
        novExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
    }
    
    func testSouthWest() {
        let location = CLLocation(latitude: -22.922646, longitude: -43.238628)
        let timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let janExpected = ExpectedValues(
            solarNoon: (12, 04, 49),
            sunrise: (05, 27),
            sunset:  (18, 43),
            fajr: (04, 03, 09),
            asr:  (15, 25, 16),
            isha: (20, 01, 05)
        )
        
        janExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 4
        dateComponents.day = 6
        
        let aprExpected = ExpectedValues(
            solarNoon: (11, 55, 19),
            sunrise: (06, 03),
            sunset:  (17, 48),
            fajr: (04, 47, 58),
            asr:  (15, 17, 23),
            isha: (18, 58, 42)
        )
        
        aprExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
    }
    
    func testSouthEast() {
        let location = CLLocation(latitude: -29.856687, longitude: 31.017086)
        let timeZone = TimeZone(identifier: "Africa/Johannesburg")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timeZone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let janExpected = ExpectedValues(
            solarNoon: (12, 07, 45),
            sunrise: (05, 17),
            sunset:  (18, 58),
            fajr: (03, 44, 20),
            asr:  (15, 43, 41),
            isha: (20, 24, 41)
        )
        
        janExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 5
        dateComponents.day = 15
        
        let mayExpected = ExpectedValues(
            solarNoon: (11, 52, 18),
            sunrise: (06, 33),
            sunset:  (17, 11),
            fajr: (05, 10, 06),
            asr:  (14, 51, 14),
            isha: (18, 29, 45)
        )
        
        mayExpected.validateDay(dateComponents: dateComponents, location: location, configuration: configuration)
    }
    
}

private extension Date {
    func timeBetween(_ dateComponents: DateComponents, _ hourMinute: HourMinute) -> TimeInterval {
        var componentsCopy = dateComponents
        componentsCopy.hour = hourMinute.hour
        componentsCopy.minute = hourMinute.minute
        return timeIntervalSince(componentsCopy.date!).magnitude
    }
    func timeBetween(_ dateComponents: DateComponents, _ hourMinuteSecond: HourMinuteSecond) -> TimeInterval {
        var componentsCopy = dateComponents
        componentsCopy.hour = hourMinuteSecond.hour
        componentsCopy.minute = hourMinuteSecond.minute
        componentsCopy.second = hourMinuteSecond.second
        return timeIntervalSince(componentsCopy.date!).magnitude
    }
}
