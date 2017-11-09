//
//  DataSourceTests.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
import CoreLocation
@testable import OpenLocate

class MockCLLocationManager: CLLocationManagerType {
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters

    var monitoredRegions: Set<CLRegion> {
        return Set([CLRegion]())
    }

    weak var delegate: CLLocationManagerDelegate?

    var location: CLLocation?

    var didStartUpdating = false

    static func locationServicesEnabled() -> Bool {
        return true
    }

    static func authorizationStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse
    }

    func startMonitoringVisits() {
        didStartUpdating = true
    }

    func startMonitoringSignificantLocationChanges() {}

    func stopMonitoringVisits() {}

    func stopMonitoringSignificantLocationChanges() {}

    func requestAlwaysAuthorization() {}

    func requestWhenInUseAuthorization() {}

    func stopUpdatingLocation() {}

    func requestLocation() {}

    func startMonitoring(for region: CLRegion) {}

    func stopMonitoring(for region: CLRegion) {}
}

class LocationManagerTests: BaseTestCase {

    func testLocationManagerDefaultState() {
        // Given
        let manager = LocationManager(manager: MockCLLocationManager())

        // Then
        XCTAssertFalse(manager.updatingLocation)
    }

    func testLocationManagerAfterSubscribing() {
        // Given
        let manager = LocationManager(manager: MockCLLocationManager())
        manager.subscribe { _ in }

        // Then
        XCTAssertTrue(manager.updatingLocation)
    }

    func testLocationManagerAfterUnSubscribing() {
        // Given
        let manager = LocationManager(manager: MockCLLocationManager())
        manager.subscribe { _ in }
        manager.cancel()

        // Then
        XCTAssertFalse(manager.updatingLocation)
    }

    func testLocationManagerSubscriptionOnUpdateLocation() {
        // Given
        let timeout: TimeInterval = 0.1
        let locationManager = MockCLLocationManager()
        let manager = LocationManager(manager: locationManager)
        let expect = expectation(description: "Update location should call the callback")
        let location = CLLocation(latitude: 12.43, longitude: 124.43)

        manager.subscribe { _ in
            XCTAssertTrue(true)
            expect.fulfill()
        }

        // Then
        manager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testLocationManagerSubscriptionOnEmptyLocation() {
        // Given
        let locationManager = MockCLLocationManager()
        let manager = LocationManager(manager: locationManager)

        manager.subscribe { _ in }

        // Then
        manager.locationManager(CLLocationManager(), didUpdateLocations: [])
        XCTAssertTrue(true)
    }

    func testLocationManagerOnChangeAuthorization() {
        // Given
        let locationManager = MockCLLocationManager()
        let manager = LocationManager(manager: locationManager)
        manager.subscribe { _ in
            // Nothing
        }

        // When
        manager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedAlways)

        // Then
        XCTAssertTrue(locationManager.didStartUpdating)
    }

}
