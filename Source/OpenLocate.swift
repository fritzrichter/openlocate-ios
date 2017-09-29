//
//  OpenLocate.swift
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
import AdSupport

public typealias LocationCompletionHandler = (OpenLocateLocation?, Error?) -> Void

private protocol OpenLocateType {
    static var shared: OpenLocate { get }

    var isTrackingEnabled: Bool { get }

    func initialize(with configuration: Configuration) throws

    func startTracking()
    func stopTracking()

    func fetchCurrentLocation(completion: LocationCompletionHandler) throws
}

public final class OpenLocate: OpenLocateType {
    private enum Constants {
        static let defaultTransmissionInterval: TimeInterval = 8 * 60 * 60 // 8 Hours
    }

    private var locationService: LocationServiceType?

    fileprivate var configuration: Configuration?

    public static let shared = OpenLocate()
}

extension OpenLocate {
    private func initLocationService(configuration: Configuration) {
        let httpClient = HttpClient()

        let locationDataSource: LocationDataSourceType

        do {
            let database = try SQLiteDatabase.openLocateDatabase()
            locationDataSource = LocationDatabase(database: database)
        } catch {
            locationDataSource = LocationList()
        }

        let locationManager = LocationManager()

        self.configuration = configuration

        self.locationService = LocationService(
            postable: httpClient,
            locationDataSource: locationDataSource,
            url: configuration.url.absoluteString,
            headers: configuration.headers,
            advertisingInfo: advertisingInfo,
            locationManager: locationManager,
            transmissionInterval: Constants.defaultTransmissionInterval,
            logConfiguration: configuration.logConfiguration
        )

        if let locationService = self.locationService, locationService.isStarted {
            locationService.start()
        }
    }

    public func initialize(with configuration: Configuration) throws {
        try validateLocationAuthorizationKeys()

        initLocationService(configuration: configuration)
    }

    public func startTracking() {
        locationService?.start()
    }

    public func stopTracking() {
        guard let service = locationService else {
            debugPrint("Trying to stop server even if it was never started.")

            return
        }

        service.stop()
    }

    public var isTrackingEnabled: Bool {
        guard let locationService = self.locationService else { return false }

        return locationService.isStarted
    }

    private var advertisingInfo: AdvertisingInfo {
        let manager = ASIdentifierManager.shared()
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: manager.advertisingIdentifier.uuidString)
            .set(isLimitedAdTrackingEnabled: manager.isAdvertisingTrackingEnabled)
            .build()

        return advertisingInfo
    }
}

extension OpenLocate {
    public func fetchCurrentLocation(completion: (OpenLocateLocation?, Error?) -> Void) throws {
        try validateLocationAuthorizationKeys()

        let manager = LocationManager()
        let lastLocation = manager.lastLocation

        guard let location = lastLocation else {
            completion(
                nil,
                OpenLocateError.locationFailure(message: OpenLocateError.ErrorMessage.noCurrentLocationExists))
            return
        }

        let logConfiguration = configuration?.logConfiguration ?? .default
        let networkInfo = logConfiguration.shouldLogNetworkInfo ? NetworkInfo.currentNetworkInfo() : NetworkInfo()
        let course = logConfiguration.shouldLogDeviceCourse ? location.course : nil

        let openlocateLocation = OpenLocateLocation(location: location,
                                                    advertisingInfo: advertisingInfo,
                                                    networkInfo: networkInfo,
                                                    course: course)
        completion(openlocateLocation, nil)
    }
}

extension OpenLocate {
    private func validateLocationAuthorizationKeys() throws {
        if !LocationService.isAuthorizationKeysValid() {
            debugPrint(OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage)
            throw OpenLocateError.locationMissingAuthorizationKeys(
                message: OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage
            )
        }
    }
}
