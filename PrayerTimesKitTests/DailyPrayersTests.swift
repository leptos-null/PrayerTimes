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

class DailyPrayersTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNorthEast() {
        let location = CLLocation(latitude: 21.422495, longitude: 39.826158)
        let timezone = TimeZone(identifier: "Asia/Riyadh")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18.5, ishaAngle: 19)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timezone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timezone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let dailyJan = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 12, 32, 30) < 60)
        XCTAssert(dailyJan.fajr.dateInterval.end.timeBetween(dateComponents, 07, 01) < 120)
        XCTAssert(dailyJan.maghrib.dateInterval.start.timeBetween(dateComponents, 18, 05) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 05, 40, 55) < 2)
        XCTAssert(dailyJan.asr.dateInterval.start.timeBetween(dateComponents, 15, 41, 57) < 2)
        XCTAssert(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 19, 26, 04) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 11
        dateComponents.day = 21
        
        let dailyNov = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyNov.dhuhr.dateInterval.start.timeBetween(dateComponents, 12, 06, 30) < 60)
        XCTAssert(dailyNov.fajr.dateInterval.end.timeBetween(dateComponents, 06, 35) < 120)
        XCTAssert(dailyNov.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 38) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyNov.fajr.dateInterval.start.timeBetween(dateComponents, 05, 15, 25) < 2)
        XCTAssert(dailyNov.asr.dateInterval.start.timeBetween(dateComponents, 15, 15, 30) < 2)
        XCTAssert(dailyNov.isha.dateInterval.start.timeBetween(dateComponents, 18, 59, 38) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyNov.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyNov.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyNov.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
    }
    
    func testNorthWest() {
        let location = CLLocation(latitude: 37.334900, longitude: -122.009020)
        let timezone = TimeZone(identifier: "America/Los_Angeles")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 15, ishaAngle: 15)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timezone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timezone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let dailyJan = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 12, 19, 58) < 60)
        XCTAssert(dailyJan.fajr.dateInterval.end.timeBetween(dateComponents, 07, 17) < 120)
        XCTAssert(dailyJan.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 23) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 06, 02, 28) < 2)
        XCTAssert(dailyJan.asr.dateInterval.start.timeBetween(dateComponents, 15, 01, 42) < 2)
        XCTAssert(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 18, 36, 59) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // day of time change, before the change
        dateComponents.year = 2022
        dateComponents.month = 3
        dateComponents.day = 13
        dateComponents.hour = 0
        dateComponents.minute = 1
        
        let dailyMarPre = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyMarPre.dhuhr.dateInterval.start.timeBetween(dateComponents, 13, 17, 23) < 60)
        XCTAssert(dailyMarPre.fajr.dateInterval.end.timeBetween(dateComponents, 07, 22) < 120)
        XCTAssert(dailyMarPre.maghrib.dateInterval.start.timeBetween(dateComponents, 19, 14) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyMarPre.fajr.dateInterval.start.timeBetween(dateComponents, 06, 11, 13) < 2)
        XCTAssert(dailyMarPre.asr.dateInterval.start.timeBetween(dateComponents, 16, 38, 43) < 2)
        XCTAssert(dailyMarPre.isha.dateInterval.start.timeBetween(dateComponents, 20, 24, 03) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyMarPre.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyMarPre.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyMarPre.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // day of time change, after the change
        dateComponents.year = 2022
        dateComponents.month = 3
        dateComponents.day = 13
        dateComponents.hour = 8
        
        let dailyMarPost = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyMarPost.dhuhr.dateInterval.start.timeBetween(dateComponents, 13, 17, 23) < 60)
        XCTAssert(dailyMarPost.fajr.dateInterval.end.timeBetween(dateComponents, 07, 22) < 120)
        XCTAssert(dailyMarPost.maghrib.dateInterval.start.timeBetween(dateComponents, 19, 14) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyMarPost.fajr.dateInterval.start.timeBetween(dateComponents, 06, 11, 13) < 2)
        XCTAssert(dailyMarPost.asr.dateInterval.start.timeBetween(dateComponents, 16, 38, 43) < 2)
        XCTAssert(dailyMarPost.isha.dateInterval.start.timeBetween(dateComponents, 20, 24, 03) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyMarPost.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyMarPost.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyMarPost.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // day of time change, before the change
        dateComponents.year = 2022
        dateComponents.month = 11
        dateComponents.day = 6
        dateComponents.hour = 0
        dateComponents.minute = 1
        
        let dailyNovPre = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyNovPre.dhuhr.dateInterval.start.timeBetween(dateComponents, 11, 51, 38) < 60)
        XCTAssert(dailyNovPre.fajr.dateInterval.end.timeBetween(dateComponents, 06, 38) < 120)
        XCTAssert(dailyNovPre.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 05) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyNovPre.fajr.dateInterval.start.timeBetween(dateComponents, 05, 23, 48) < 2)
        XCTAssert(dailyNovPre.asr.dateInterval.start.timeBetween(dateComponents, 14, 43, 35) < 2)
        XCTAssert(dailyNovPre.isha.dateInterval.start.timeBetween(dateComponents, 18, 19, 28) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyNovPre.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyNovPre.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyNovPre.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // day of time change, after the change
        dateComponents.year = 2022
        dateComponents.month = 11
        dateComponents.day = 6
        dateComponents.hour = 8
        
        let dailyNovPost = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyNovPost.dhuhr.dateInterval.start.timeBetween(dateComponents, 11, 51, 38) < 60)
        XCTAssert(dailyNovPost.fajr.dateInterval.end.timeBetween(dateComponents, 06, 38) < 120)
        XCTAssert(dailyNovPost.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 05) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyNovPost.fajr.dateInterval.start.timeBetween(dateComponents, 05, 23, 48) < 2)
        XCTAssert(dailyNovPost.asr.dateInterval.start.timeBetween(dateComponents, 14, 43, 35) < 2)
        XCTAssert(dailyNovPost.isha.dateInterval.start.timeBetween(dateComponents, 18, 19, 28) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyNovPost.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyNovPost.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyNovPost.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
    }
    
    func testSouthWest() {
        let location = CLLocation(latitude: -22.922646, longitude: -43.238628)
        let timezone = TimeZone(identifier: "America/Sao_Paulo")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timezone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timezone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let dailyJan = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 12, 04, 49) < 60)
        XCTAssert(dailyJan.fajr.dateInterval.end.timeBetween(dateComponents, 05, 27) < 120)
        XCTAssert(dailyJan.maghrib.dateInterval.start.timeBetween(dateComponents, 18, 43) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 04, 03, 09) < 2)
        XCTAssert(dailyJan.asr.dateInterval.start.timeBetween(dateComponents, 15, 25, 16) < 2)
        XCTAssert(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 20, 01, 05) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 4
        dateComponents.day = 6
        
        let dailyApr = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyApr.dhuhr.dateInterval.start.timeBetween(dateComponents, 11, 55, 19) < 60)
        XCTAssert(dailyApr.fajr.dateInterval.end.timeBetween(dateComponents, 06, 03) < 120)
        XCTAssert(dailyApr.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 48) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyApr.fajr.dateInterval.start.timeBetween(dateComponents, 04, 47, 58) < 2)
        XCTAssert(dailyApr.asr.dateInterval.start.timeBetween(dateComponents, 15, 17, 23) < 2)
        XCTAssert(dailyApr.isha.dateInterval.start.timeBetween(dateComponents, 18, 58, 42) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyApr.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyApr.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyApr.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
    }
    
    func testSouthEast() {
        let location = CLLocation(latitude: -29.856687, longitude: 31.017086)
        let timezone = TimeZone(identifier: "Africa/Johannesburg")!
        let configuration = CalculationConfiguration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
        
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timezone
        
        var dateComponents = DateComponents(calendar: gregorianCalendar, timeZone: timezone)
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 23
        
        let dailyJan = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 12, 07, 45) < 60)
        XCTAssert(dailyJan.fajr.dateInterval.end.timeBetween(dateComponents, 05, 17) < 120)
        XCTAssert(dailyJan.maghrib.dateInterval.start.timeBetween(dateComponents, 18, 58) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 03, 45, 29) < 2)
        XCTAssert(dailyJan.asr.dateInterval.start.timeBetween(dateComponents, 15, 44, 00) < 2)
        XCTAssert(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 20, 24, 05) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyJan.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyJan.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyJan.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
        
        // randomly selected date
        dateComponents.year = 2022
        dateComponents.month = 5
        dateComponents.day = 15
        
        let dailyMay = DailyPrayers(day: dateComponents.date!, timezone: timezone, location: location, configuration: configuration)
        
        // based on https://gml.noaa.gov/grad/solcalc/
        // relatively high tolerance on these values, because of the lack of seconds
        //   and these values should not change, regardless of implementation
        XCTAssert(dailyMay.dhuhr.dateInterval.start.timeBetween(dateComponents, 11, 52, 18) < 60)
        XCTAssert(dailyMay.fajr.dateInterval.end.timeBetween(dateComponents, 06, 33) < 120)
        XCTAssert(dailyMay.maghrib.dateInterval.start.timeBetween(dateComponents, 17, 11) < 120)
        
        // based on previous calculations
        // as the implementation is updated, these values may be updated
        // i.e. the purpose of these tests are to let us know if a change
        //   inadvertently results in different output
        //   (as opposed to these tests strictly representing the desired output)
        XCTAssert(dailyMay.fajr.dateInterval.start.timeBetween(dateComponents, 05, 10, 36) < 2)
        XCTAssert(dailyMay.asr.dateInterval.start.timeBetween(dateComponents, 14, 50, 45) < 2)
        XCTAssert(dailyMay.isha.dateInterval.start.timeBetween(dateComponents, 18, 29, 15) < 2)
        
        // failure cases to make sure logic is working
        XCTAssertFalse(dailyMay.fajr.dateInterval.start.timeBetween(dateComponents, 12, 00, 00) < 200)
        XCTAssertFalse(dailyMay.dhuhr.dateInterval.start.timeBetween(dateComponents, 18, 00, 00) < 200)
        XCTAssertFalse(dailyMay.isha.dateInterval.start.timeBetween(dateComponents, 4, 00, 00) < 200)
    }
    
}

private extension Date {
    func timeBetween(_ dateComponents: DateComponents, _ hour: Int, _ minute: Int, _ second: Int? = nil) -> TimeInterval {
        var copy = dateComponents
        copy.hour = hour
        copy.minute = minute
        copy.second = second
        return timeIntervalSince(copy.date!).magnitude
    }
}
