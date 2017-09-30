//
//  OpenLocateInfo.swift
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

import Foundation
import CoreLocation.CLLocation

struct OpenLocateInfo {
    let networkInfo: NetworkInfo
    let deviceLocationInfo: DeviceLocationInfo
    let deviceInfo: DeviceInfo
}

extension OpenLocateInfo {
    final class Builder {
        let logConfiguration: LogConfiguration

        private var location: CLLocation?
        private var deviceInfo: DeviceInfo?
        private var networkInfo: NetworkInfo = .currentNetworkInfo()

        init(logConfiguration: LogConfiguration) {
            self.logConfiguration = logConfiguration
        }

        func set(network: NetworkInfo) -> Builder {
            self.networkInfo = network

            return self
        }

        func set(location: CLLocation) -> Builder {
            self.location = location

            return self
        }

        func set(deviceInfo: DeviceInfo) -> Builder {
            self.deviceInfo = deviceInfo

            return self
        }

        func build() -> OpenLocateInfo {
            let networkInfo = logConfiguration.shouldLogNetworkInfo ? self.networkInfo : NetworkInfo()

            let course = logConfiguration.shouldLogDeviceCourse ? self.location?.course : nil
            let speed = logConfiguration.shouldLogDeviceSpeed ? self.location?.speed : nil
            let deviceLocationInfo = DeviceLocationInfo(deviceCourse: course, deviceSpeed: speed)

            let deviceInfo = DeviceInfo.currentDeviceInfo(withLogConfiguration: logConfiguration)

            return OpenLocateInfo(networkInfo: networkInfo,
                                  deviceLocationInfo: deviceLocationInfo,
                                  deviceInfo: deviceInfo)
        }
    }
}
