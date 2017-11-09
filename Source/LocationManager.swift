//
//  LocationManager.swift
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

typealias LocationsHandler = ([(location: CLLocation, context: OpenLocateLocation.Context)]) -> Void

// Location Manager

protocol LocationManagerType {
    func subscribe(_ locationHandler: @escaping LocationsHandler)
    func cancel()

    var updatingLocation: Bool { get }
    var lastLocation: CLLocation? { get }

    func fetchLocation(onCompletion: @escaping ((Bool) -> Void))
}

final class LocationManager: NSObject, LocationManagerType, CLLocationManagerDelegate {

    static let visitRegionIdentifier = "VisitRegion"
    static let minimumVisitRegionRadius = 25.0

    private let manager: CLLocationManagerType
    private var requests: [LocationsHandler] = []
    private var fetchLocationCompletionHandler: ((Bool) -> Void)?

    required init(manager: CLLocationManagerType = CLLocationManager()) {
        self.manager = manager

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    static func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    static func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    func fetchLocation(onCompletion: @escaping ((Bool) -> Void)) {
        manager.requestLocation()
        self.fetchLocationCompletionHandler = onCompletion
    }

    // MARK: CLLocationManager

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        var date = Date()
        var context = OpenLocateLocation.Context.unknown
        if visit.departureDate != Date.distantFuture {
            date = visit.departureDate
            context = .visitExit

            startMonitoringVisitRegion(with: visit.coordinate, maxRadius: visit.horizontalAccuracy)
        } else if visit.arrivalDate != Date.distantPast {
            date = visit.arrivalDate
            context = .visitEntry

            stopMonitoringVisitRegion()
        }

        let location = CLLocation(coordinate: visit.coordinate,
                                  altitude: 0,
                                  horizontalAccuracy: visit.horizontalAccuracy,
                                  verticalAccuracy: -1.0,
                                  timestamp: date)

        var locations = [(location: location, context: context)]
        if let currentLocation = manager.location {
            locations.append((location: currentLocation, context: .passive))
        }

        for request in requests {
            request(locations)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for request in requests {
            request(locations.map({return (location: $0, context: OpenLocateLocation.Context.backgroundFetch)}))
        }
        if let fetchLocationCompletionHandler = self.fetchLocationCompletionHandler {
            fetchLocationCompletionHandler(true)
            self.fetchLocationCompletionHandler = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let location = manager.location {
            for request in requests {
                request([(location: location, context: OpenLocateLocation.Context.geofenceEntry)])
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let location = manager.location {
            for request in requests {
                request([(location: location, context: OpenLocateLocation.Context.geofenceExit)])
            }
            startMonitoringVisitRegion(with: location.coordinate, maxRadius: location.horizontalAccuracy)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)

        if let fetchLocationCompletionHandler = self.fetchLocationCompletionHandler {
            fetchLocationCompletionHandler(false)
            self.fetchLocationCompletionHandler = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways && updatingLocation {
            manager.startMonitoringVisits()
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    // MARK: LocationManagerType

    func subscribe(_ locationHandler: @escaping LocationsHandler) {
        requests.append(locationHandler)
        requestAuthorizationIfNeeded()
        manager.startMonitoringVisits()
        manager.startMonitoringSignificantLocationChanges()
    }

    func cancel() {
        requests.removeAll()
        manager.stopMonitoringVisits()
        manager.stopMonitoringSignificantLocationChanges()
    }

    var updatingLocation: Bool {
        return !requests.isEmpty
    }

    // MARK: Private

    private func startMonitoringVisitRegion(with coordinate: CLLocationCoordinate2D, maxRadius: CLLocationDistance) {
        let region = CLCircularRegion(center: coordinate,
                                      radius: max(LocationManager.minimumVisitRegionRadius, maxRadius),
                                      identifier: LocationManager.visitRegionIdentifier)
        manager.startMonitoring(for: region)
    }

    private func stopMonitoringVisitRegion() {
        let regions = manager.monitoredRegions.filter({ $0.identifier == LocationManager.visitRegionIdentifier })
        regions.forEach { manager.stopMonitoring(for: $0) }
    }

    private func requestAuthorizationIfNeeded() {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    var lastLocation: CLLocation? {
        return manager.location
    }
}
