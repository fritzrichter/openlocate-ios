//
//  LocationTests.swift
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

final class OpenLocateLocationTests: BaseTestCase {
    func testOpenLocateLocationGivesCorrectValues() {
        //Given
        let coreLocation = CLLocation(
            coordinate: CLLocationCoordinate2DMake(10.0, 10.0),
            altitude: 30.0,
            horizontalAccuracy: 10,
            verticalAccuracy: 0,
            course: 180,
            speed: 20,
            timestamp: Date(timeIntervalSince1970: 1234)
        )

        let adInfo = AdvertisingInfo.Builder().set(advertisingId: "2345").set(isLimitedAdTrackingEnabled: true).build()
        let networkInfo = NetworkInfo(bssid: "bssid_goes_here", ssid: "ssid_goes_here")

        let info = OpenLocateInfo.Builder(logConfiguration: .default)
            .set(location: coreLocation)
            .set(network: networkInfo)
            .build()

        //When
        let location = OpenLocateLocation(location: coreLocation,
                                          advertisingInfo: adInfo,
                                          info: info,
                                          context: .visitExit)
        let jsonDict = location.json as? JsonDictionary
        let json = jsonDict!

        //Then
        XCTAssertEqual((json["latitude"] as? Double)!, Double(exactly: 10.0))
        XCTAssertEqual((json["longitude"] as? Double)!, Double(exactly: 10.0))
        XCTAssertEqual((json["utc_timestamp"] as? Int)!, 1234)
        XCTAssertEqual((json["horizontal_accuracy"] as? Double)!, Double(exactly: 10))
        XCTAssertEqual((json["ad_id"] as? String)!, "2345")
        XCTAssertEqual((json["ad_opt_out"] as? Bool)!, true)
        XCTAssertEqual((json["id_type"] as? String)!, "idfa")
        XCTAssertEqual((json["wifi_bssid"] as? String)!, "bssid_goes_here")
        XCTAssertEqual((json["wifi_ssid"] as? String)!, "ssid_goes_here")
        XCTAssertEqual((json["course"] as? Double)!, Double(exactly: 180.0))
        XCTAssertEqual((json["speed"] as? Double)!, Double(exactly: 20.0))
        XCTAssertEqual((json["location_context"] as? String)!, "visit_exit")
    }
}
