//
//  CLLocationManagerType.swift
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

import CoreLocation

protocol CLLocationManagerType: class {
    weak var delegate: CLLocationManagerDelegate? { get set }

    /// The last location received. Will be nil until a location has been received.
    var location: CLLocation? { get }

    var monitoredRegions: Set<CLRegion> { get }

    /// The desired location accuracy. The location service will try its best to achieve your desired accuracy.
    var desiredAccuracy: CLLocationAccuracy { get set }

    /// Determines whether the user has location services enabled.
    static func locationServicesEnabled() -> Bool

    /// Returns the current authorization status of the calling application.
    static func authorizationStatus() -> CLAuthorizationStatus

    /// Starts the delivery of visit-related events.
    func startMonitoringVisits()

    /// Starts the generation of updates based on significant location changes.
    func startMonitoringSignificantLocationChanges()

    /// Calling this method disables the delivery of visit-related events for your app.
    func stopMonitoringVisits()

    /// Stops the delivery of location events based on significant location changes.
    func stopMonitoringSignificantLocationChanges()

    /// Request authorization to use location services at any time.
    func requestAlwaysAuthorization()

    /// Requests permission to use location services while the app is in the foreground.
    func requestWhenInUseAuthorization()

    func requestLocation()

    func startMonitoring(for region: CLRegion)

    func stopMonitoring(for region: CLRegion)
}

extension CLLocationManager: CLLocationManagerType {}
