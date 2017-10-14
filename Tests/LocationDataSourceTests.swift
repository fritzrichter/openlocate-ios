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
@testable import OpenLocate
import CoreLocation

class LocationDataSourceTests: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(
            coordinate: CLLocationCoordinate2DMake(123.12, 123.123),
            altitude: 30.0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            course: 180,
            speed: 20,
            timestamp: Date(timeIntervalSince1970: 1234)
        )

        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()

        let networkInfo = NetworkInfo(bssid: "bssid_goes_here", ssid: "ssid_goes_here")
        let deviceInfo = DeviceCollectingFields(isCharging: false, deviceModel: "iPhone9,4", osVersion: "iOS 11.0.1")

        let info = CollectingFields.Builder(configuration: .default)
            .set(location: coreLocation)
            .set(network: networkInfo)
            .set(deviceInfo: deviceInfo)
            .build()

        return OpenLocateLocation(
            timestamp: coreLocation.timestamp,
            advertisingInfo: advertisingInfo,
            collectingFields: info
        )
    }

    override func setUp() {
        do {
            let database = try SQLiteDatabase.testDB()
            dataSource = LocationDatabase(database: database)
            _ = dataSource!.clear()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        let expectation = self.expectation(description: "Counting locations")

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        // Then
        locations.count { count in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        let expectation = self.expectation(description: "Counting locations")

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        // Then
        locations.count { count in
            XCTAssertEqual(count, 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testPopAllLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        let expectation = self.expectation(description: "Retireving locations and counting them")

        locations.all { popped in
            locations.clear()

            // Then
            XCTAssertEqual(popped.count, 4)
            locations.count(completion: { count in
                XCTAssertEqual(count, 0)

                expectation.fulfill()
            })
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testFirstLocation() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        let expectation = self.expectation(description: "Retrieving location")

        locations.first { location in
            // Then
            do {
                let firstLocation = try OpenLocateLocation(data: location!.data)
                XCTAssertEqual(firstLocation.location.coordinate.latitude,
                               self.testLocation.location.coordinate.latitude)
                XCTAssertEqual(firstLocation.location.coordinate.longitude,
                               self.testLocation.location.coordinate.longitude)
                XCTAssertEqual(firstLocation.location.timestamp.timeIntervalSince1970,
                               self.testLocation.location.timestamp.timeIntervalSince1970, accuracy: 0.1)

                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 0.5)
    }
}

class LocationListDataSource: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(
            coordinate: CLLocationCoordinate2DMake(123.12, 123.123),
            altitude: 30.0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            course: 180,
            speed: 20,
            timestamp: Date(timeIntervalSince1970: 1234)
        )

        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()

        let networkInfo = NetworkInfo(bssid: "bssid_goes_here", ssid: "ssid_goes_here")
        let deviceInfo = DeviceCollectingFields(isCharging: false, deviceModel: "iPhone9,4", osVersion: "iOS 11.0.1")

        let info = CollectingFields.Builder(configuration: .default)
            .set(location: coreLocation)
            .set(network: networkInfo)
            .set(deviceInfo: deviceInfo)
            .build()

        return OpenLocateLocation(
            timestamp: coreLocation.timestamp,
            advertisingInfo: advertisingInfo,
            collectingFields: info
        )
    }

    override func setUp() {
        dataSource = LocationList()
        _ = dataSource!.clear()
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        let expectation = self.expectation(description: "Adding location and counting it")

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        locations.count { count in
            // Then
            XCTAssertEqual(count, 1)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        let expectation = self.expectation(description: "Adding locations and count them")

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        locations.count { count in
            // Then
            XCTAssertEqual(count, 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testPopLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        let expectation = self.expectation(description: "Retireving locations and counting them")

        locations.all { popped in
            locations.clear()

            // Then
            XCTAssertEqual(popped.count, 4)
            locations.count(completion: { count in
                XCTAssertEqual(count, 0)
                expectation.fulfill()
            })
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func testFirstLocation() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        let expectation = self.expectation(description: "Retireving location")

        locations.first { location in
            guard let location = location else {
                XCTFail("Location cannot be nil")

                return
            }

            // Then
            do {
                let firstLocation = try OpenLocateLocation(data: location.data)
                XCTAssertEqual(firstLocation.locationFields.coordinate.latitude,
                               self.testLocation.locationFields.coordinate.latitude)
                XCTAssertEqual(firstLocation.locationFields.coordinate.longitude,
                               self.testLocation.locationFields.coordinate.longitude)
                XCTAssertEqual(firstLocation.locationFields.course, self.testLocation.location.course)
                XCTAssertEqual(firstLocation.locationFields.speed, self.testLocation.location.speed)
                XCTAssertEqual(firstLocation.deviceInfo.isCharging, testLocation.deviceInfo.isCharging)
                XCTAssertEqual(firstLocation.deviceInfo.deviceModel, testLocation.deviceInfo.deviceModel)
                XCTAssertEqual(firstLocation.locationFields.timestamp!.timeIntervalSince1970,
                               self.testLocation.locationFields.timestamp!.timeIntervalSince1970, accuracy: 0.1)

                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 0.5)
    }
}
