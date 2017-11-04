//
//  LocationCollectingFields.swift
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

import CoreLocation.CLLocation

/// Location fields' values which are sending from device
public struct LocationCollectingFields {
    /// Course of the location in degrees true North
    public let course: Double?

    /// Speed of the location in m/s
    public let speed: Double?

    /// The geographical coordinate information
    public let coordinates: CLLocationCoordinate2D?

    /// The time at which this location was determined
    public let timestamp: Date?

    /// The radius of uncertainty for the location, measured in meters
    public let horizontalAccuracy: CLLocationAccuracy?

    /// The accuracy of the altitude value, measured in meters
    public let verticalAccuracy: CLLocationAccuracy?

    /// The altitude, measured in meters
    public let altitude: CLLocationDistance?
}
