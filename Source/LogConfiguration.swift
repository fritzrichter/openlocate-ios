//
//  LogConfiguration.swift
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

/// Configuration which describes all data which is sending from the device
public struct LogConfiguration {
    /// Determines whether network information is sending or not. Default value is true.
    public var shouldLogNetworkInfo: Bool

    /// Determines whether device course (bearing) is sending or not. Default value is true.
    public var shouldLogDeviceCourse: Bool

    /// Determines whether device speed is sending or not. Default value is true.
    public var shouldLogDeviceSpeed: Bool

    /// Determines whether device charging status should be sent ot not. Default value is true.
    public var shouldLogDeviceCharging: Bool

    /// Determines whether device model should be sent. Default value is true.
    public var shouldLogDeviceModel: Bool

    /// Determines whether device's os version is sent. Default value is true.
    public var shouldLogDeviceOsVersion: Bool

    /// Default configuration. All parameters are set to true.
    public static let `default` = LogConfiguration(
        shouldLogNetworkInfo: true,
        shouldLogDeviceCourse: true,
        shouldLogDeviceSpeed: true,
        shouldLogDeviceCharging: true,
        shouldLogDeviceModel: true,
        shouldLogDeviceOsVersion: true
    )
}
