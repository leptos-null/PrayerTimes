//
//  LocationsCourseTest.swift
//  PrayerTimesKitTests
//
//  Created by Leptos on 2/18/22.
//

import XCTest
import CoreLocation
@testable import PrayerTimesKit

// originally checked with https://earthdirections.org/locate/

class LocationsCourseTest: XCTestCase {
    
    func testMedinaToMecca() {
        let medina = CLLocationCoordinate2D(latitude: 24.46325, longitude: 39.60393)
        let mecca = CLLocationCoordinate2D(latitude: 21.40657, longitude: 39.81826)
        let course = medina.course(to: mecca)
        XCTAssertEqual(course, 176.3, accuracy: 1)
    }
    
    func testCaracasToMecca() {
        let caracas = CLLocationCoordinate2D(latitude: 10.50556, longitude: -66.91467)
        let mecca = CLLocationCoordinate2D(latitude: 21.40657, longitude: 39.81826)
        let course = caracas.course(to: mecca)
        XCTAssertEqual(course, 65.4, accuracy: 1)
    }
    
    func testFijiToMecca() {
        let fiji = CLLocationCoordinate2D(latitude: -17.79299, longitude: 177.98481)
        let mecca = CLLocationCoordinate2D(latitude: 21.40657, longitude: 39.81826)
        let course = fiji.course(to: mecca)
        XCTAssertEqual(course, 282.3, accuracy: 1)
    }
    
    func testMelbourneToMecca() {
        let melbourne = CLLocationCoordinate2D(latitude: -37.81554, longitude: 144.96645)
        let mecca = CLLocationCoordinate2D(latitude: 21.40657, longitude: 39.81826)
        let course = melbourne.course(to: mecca)
        XCTAssertEqual(course, 278.8, accuracy: 1)
    }
    
    func testHawaiiToMecca() {
        let hawaii = CLLocationCoordinate2D(latitude: 21.30790, longitude: -157.85660)
        let mecca = CLLocationCoordinate2D(latitude: 21.40657, longitude: 39.81826)
        let course = hawaii.course(to: mecca)
        XCTAssertEqual(course, 336.9, accuracy: 1)
    }
    
    func testFijiToHawaii() {
        // sign change in both latitude and longitude
        let fiji = CLLocationCoordinate2D(latitude: -17.79299, longitude: 177.98481)
        let hawaii = CLLocationCoordinate2D(latitude: 21.30790, longitude: -157.85660)
        let course = fiji.course(to: hawaii)
        XCTAssertEqual(course, 32.2, accuracy: 1)
    }
    
    func testHawaiiToFiji() {
        // sign change in both latitude and longitude
        let hawaii = CLLocationCoordinate2D(latitude: 21.30790, longitude: -157.85660)
        let fiji = CLLocationCoordinate2D(latitude: -17.79299, longitude: 177.98481)
        let course = hawaii.course(to: fiji)
        XCTAssertEqual(course, 213.0, accuracy: 1)
    }
    
    func testMadridToIstanbul() {
        let madrid = CLLocationCoordinate2D(latitude: 40.41959, longitude: -3.69278)
        let istanbul = CLLocationCoordinate2D(latitude: 41.01180, longitude: 28.97543)
        let course = madrid.course(to: istanbul)
        XCTAssertEqual(course, 77.8, accuracy: 1)
    }
    
    func testIstanbulToMadrid() {
        let istanbul = CLLocationCoordinate2D(latitude: 41.01180, longitude: 28.97543)
        let madrid = CLLocationCoordinate2D(latitude: 40.41959, longitude: -3.69278)
        let course = istanbul.course(to: madrid)
        XCTAssertEqual(course, 279.5, accuracy: 1)
    }
    
}
