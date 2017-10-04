//
//  LocationService.swift
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
import CoreLocation

protocol LocationServiceType {
    var transmissionInterval: TimeInterval { get set }

    var isStarted: Bool { get }

    func start()
    func stop()
}

private let locationsKey = "locations"

final class LocationService: LocationServiceType {

    let isStartedKey = "OpenLocate_isStarted"

    let logConfiguration: LogConfiguration

    var transmissionInterval: TimeInterval

    var isStarted: Bool {
        return UserDefaults.standard.bool(forKey: isStartedKey)
    }

    private let locationManager: LocationManagerType
    private let httpClient: Postable
    private let locationDataSource: LocationDataSourceType
    private var advertisingInfo: AdvertisingInfo

    private var url: String
    private var headers: Headers?

    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    init(
        postable: Postable,
        locationDataSource: LocationDataSourceType,
        url: String,
        headers: Headers?,
        advertisingInfo: AdvertisingInfo,
        locationManager: LocationManagerType,
        transmissionInterval: TimeInterval,
        logConfiguration: LogConfiguration) {

        httpClient = postable
        self.locationDataSource = locationDataSource
        self.locationManager = locationManager
        self.advertisingInfo = advertisingInfo
        self.url = url
        self.headers = headers
        self.transmissionInterval = transmissionInterval
        self.logConfiguration = logConfiguration
    }

    func start() {
        debugPrint("Location service started for url : \(url)")

        locationManager.subscribe { locations in

            let openLocateLocations: [OpenLocateLocation] = locations.map {
                let info = OpenLocateInfo.Builder(logConfiguration: self.logConfiguration)
                    .set(location: $0.location)
                    .set(network: NetworkInfo.currentNetworkInfo())
                    .build()
                return OpenLocateLocation(location: $0.location,
                                          advertisingInfo: self.advertisingInfo,
                                          openLocateInfo: info,
                                          context: $0.context)
            }

            self.locationDataSource.addAll(locations: openLocateLocations)

            debugPrint(self.locationDataSource.count)

            self.postAllLocationsIfNeeded()
        }

        UserDefaults.standard.set(true, forKey: isStartedKey)
    }

    func stop() {
        locationManager.cancel()
        UserDefaults.standard.set(false, forKey: isStartedKey)
        postAllLocations()
    }

}

extension LocationService {

    private func postAllLocationsIfNeeded() {
        if let earliestIndexedLocation = locationDataSource.first() {
            do {
                let earliestLocation = try OpenLocateLocation(data: earliestIndexedLocation.1.data)
                if abs(earliestLocation.location.timestamp.timeIntervalSinceNow) > self.transmissionInterval {
                    postAllLocations()
                }
            } catch {
                debugPrint(error)
            }
        }
    }

    private func postAllLocations() {
        let indexedLocations = locationDataSource.all()
        if indexedLocations.isEmpty == false {
            locationDataSource.clear()
            let locations = indexedLocations.map { $1 }
            self.postLocations(locations: locations)
        }
    }

    private func postLocations(locations: [OpenLocateLocationType]) {

        if locations.isEmpty {
            return
        }

        let params = [locationsKey: locations.map { $0.json }]

        beginBackgroundTask()

        let requestParameters
            = URLRequestParamters(url: url,
                                  params: params,
                                  queryParams: nil,
                                  additionalHeaders: headers)

        do {
            try httpClient.post(
                parameters: requestParameters,
                success: {  [weak self] _, _ in
                    self?.endBackgroundTask()
            },
                failure: { [weak self] _, error in
                    debugPrint("failure in posting locations!!! Error: \(error)")
                    self?.locationDataSource.addAll(locations: locations)
                    self?.endBackgroundTask()
            }
            )
        } catch let error {
            print(error.localizedDescription)
            endBackgroundTask()
        }
    }

    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }

    static func isAuthorizationKeysValid() -> Bool {
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription")
        let inUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription")
        let alwaysAndinUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription")

        if #available(iOS 11, *) {
            return always != nil && inUse != nil && alwaysAndinUse != nil
        }

        return always != nil
    }
}
