//
//  LocationServiceTests.swift
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
@testable import OpenLocate
import CoreLocation

class LocationRequestTests: BaseTestCase {

    func testLocationServiceStart() {
        // Given
        let mockLocationManager = MockCLLocationManager()
        let locationManager = LocationManager(manager: mockLocationManager)
        let locationService = LocationService(
            postable: HttpClient(urlSession: SuccessURLSession()),
            locationDataSource: LocationList(),
            url: "http://www.google.com",
            headers: nil,
            advertisingInfo: AdvertisingInfo.Builder()
                .set(advertisingId: "1234")
                .set(isLimitedAdTrackingEnabled: true)
                .build(),
            locationManager: locationManager,
            transmissionInterval: 300,
            logConfiguration: .default
        )
        let location = CLLocation(latitude: 12.43, longitude: 124.43)

        // When
        locationService.start()
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])

        // Then
        XCTAssertTrue(true)
    }

    func testLocationServiceStop() {
        // Given
        let mockLocationManager = MockCLLocationManager()
        let locationManager = LocationManager(manager: mockLocationManager)
        let locationService = LocationService(
            postable: HttpClient(urlSession: SuccessURLSession()),
            locationDataSource: LocationList(),
            url: "http://www.google.com",
            headers: nil,
            advertisingInfo: AdvertisingInfo.Builder()
                .set(advertisingId: "1234")
                .set(isLimitedAdTrackingEnabled: true)
                .build(),
            locationManager: locationManager,
            transmissionInterval: 300,
            logConfiguration: .default
        )
        let location = CLLocation(latitude: 12.43, longitude: 124.43)

        // When
        locationService.start()
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [location])
        locationService.stop()

        // Then
        XCTAssertTrue(true)
    }
}
