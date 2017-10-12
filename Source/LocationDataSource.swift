//
//  DataSource.swift
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

typealias IndexedLocation = (Int, OpenLocateLocationType)

struct IndexLocation {
    let index: Int
    let data: Data
}

protocol LocationDataSourceType {

    func count(completion: @escaping (Int) -> Void)

    func add(location: OpenLocateLocationType) throws
    func addAll(locations: [OpenLocateLocationType])

    func first(completion: @escaping (IndexLocation?) -> Void)
    func all(completion: @escaping ([IndexLocation]) -> Void)

    func clear()
}

final class LocationDatabase: LocationDataSourceType {

    private enum Constants {
        static let tableName = "Location"
        static let columnId = "_id"
        static let columnLocation = "location"
    }

    private let database: Database

    func add(location: OpenLocateLocationType) throws {
        let query = "INSERT INTO " +
        "\(Constants.tableName) " +
        "(\(Constants.columnLocation)) " +
        "VALUES (?);"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(args: [location.data])
            .build()

        try database.execute(statement: statement, completion: nil)
    }

    func addAll(locations: [OpenLocateLocationType]) {
        guard !locations.isEmpty else { return }

        if locations.count == 1 {
            do {
                try add(location: locations.first!)
            } catch let error {
                debugPrint(error.localizedDescription)
            }

            return
        }

        database.begin()
        for location in locations {
            do {
                try add(location: location)
            } catch let error {
                debugPrint(error.localizedDescription)
                database.rollback()

                return
            }
        }

        database.commit()
    }

    func count(completion: @escaping (Int) -> Void) {
        let query = "SELECT COUNT(*) FROM \(Constants.tableName)"

        let statement = SQLStatement.Builder()
        .set(query: query)
        .set(cached: true)
        .build()

        var count = -1
        do {
            try database.execute(statement: statement, completion: { result, error in
                guard error == nil else {
                    debugPrint(error!)

                    return
                }

                result.next { _ in
                    count = Int(result.intValue(column: 0))

                    completion(count)
                }
            })
        } catch let error {
            debugPrint(error.localizedDescription)
            completion(count)
        }
    }

    func clear() {
        let query = "DELETE FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            try database.execute(statement: statement, completion: nil)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func first(completion: @escaping (IndexLocation?) -> Void) {
        let query = "SELECT * FROM \(Constants.tableName) LIMIT 1"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            try database.execute(statement: statement, completion: { [weak self] result, error in
                guard error == nil else {
                    debugPrint(error!)

                    return
                }

                result.next(block: { [weak self] hasAnotherRow in
                    if hasAnotherRow {
                        let location = self?.getLocations(fromResult: result).first
                        completion(location)
                    } else {
                        completion(nil)
                    }
                })
            })
        } catch let error {
            debugPrint(error.localizedDescription)
            completion(nil)
        }
    }

    func all(completion: @escaping ([IndexLocation]) -> Void) {
        let query = "SELECT * FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            try database.execute(statement: statement, completion: { [weak self] result, error in
                guard error == nil else {
                    debugPrint(error!)

                    return
                }

                let indexLocations: [IndexLocation] = []
                self?.getAllRows(fromResult: result, locations: indexLocations, completion: completion)
            })
        } catch let error {
            debugPrint(error.localizedDescription)

            let locations: [IndexLocation] = []
            completion(locations)
        }
    }

    private func getAllRows(fromResult result: Result,
                            locations: [IndexLocation],
                            completion: @escaping ([IndexLocation]) -> Void) {
        var locations = locations
        result.next { [weak self] hasAnotherRow in
            guard let strongSelf = self else { return }

            locations.append(contentsOf: strongSelf.getLocations(fromResult: result))

            if hasAnotherRow {
                strongSelf.getAllRows(fromResult: result, locations: locations, completion: completion)
            } else {
                completion(locations)
            }
        }
    }

    private func getLocations(fromResult result: Result) -> [IndexLocation] {
        let index = result.intValue(column: Constants.columnId)
        let data = result.dataValue(column: Constants.columnLocation)

        var locations: [IndexLocation] = []

        if let data = data { locations.append(IndexLocation(index: index, data: data)) }

        return locations
    }

    init(database: Database) {
        self.database = database
        createTableIfNotExists()
    }

    private func createTableIfNotExists(completion: ExecuteCompletion? = nil) {
        let query = "CREATE TABLE IF NOT EXISTS " +
        "\(Constants.tableName) (" +
        "\(Constants.columnId) INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "\(Constants.columnLocation) BLOB NOT NULL" +
        ");"

        let statement = SQLStatement.Builder()
        .set(query: query)
        .build()

        do {
            try database.execute(statement: statement, completion: completion)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

final class LocationList: LocationDataSourceType {

    private var locations: [OpenLocateLocationType]

    init() {
        self.locations = [OpenLocateLocationType]()
    }

    func count(completion: @escaping (Int) -> Void) {
        completion(locations.count)
    }

    func add(location: OpenLocateLocationType) {
        self.locations.append(location)
    }

    func addAll(locations: [OpenLocateLocationType]) {
        self.locations.append(contentsOf: locations)
    }

    func first(completion: @escaping (IndexLocation?) -> Void) {
        if let location = self.locations.first {
            completion(IndexLocation(index: 0, data: location.data))
        } else {
            completion(nil)
        }
    }

    func all(completion: @escaping ([IndexLocation]) -> Void) {
        let locations = self.locations.enumerated().map { IndexLocation(index: $0.offset, data: $0.element.data) }
        completion(locations)
    }

    func clear() {
        self.locations.removeAll()
    }
}
