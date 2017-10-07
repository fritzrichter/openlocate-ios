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

protocol LocationDataSourceType {

    var count: Int { get }

    func add(location: OpenLocateLocationType) throws
    func addAll(locations: [OpenLocateLocationType])

    func first() -> IndexedLocation?
    func all() -> [IndexedLocation]

    func clear()
}

final class LocationDatabase: LocationDataSourceType {

    private struct Constants {
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

        _ = try database.execute(statement: statement)
    }

    func addAll(locations: [OpenLocateLocationType]) {
        if locations.isEmpty {
            return
        }

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

    var count: Int {
        let query = "SELECT COUNT(*) FROM \(Constants.tableName)"

        let statement = SQLStatement.Builder()
        .set(query: query)
        .set(cached: true)
        .build()

        var count = -1
        do {
            let result = try database.execute(statement: statement)
            _ = result.next()
            count = Int(result.intValue(column: 0))

            return count
        } catch let error {
            debugPrint(error.localizedDescription)
            return count
        }
    }

    func clear() {
        let query = "DELETE FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            _ = try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func first() -> IndexedLocation? {
        let query = "SELECT * FROM \(Constants.tableName) LIMIT 1"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            let result = try database.execute(statement: statement)
            if result.next() {
                let index = result.intValue(column: Constants.columnId)
                let data = result.dataValue(column: Constants.columnLocation)

                if let data = data {
                    return (index, try OpenLocateLocation(data: data))
                }
            }
        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return nil
    }

    func all() -> [IndexedLocation] {
        let query = "SELECT * FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        var locations = [IndexedLocation]()

        do {
            let result = try database.execute(statement: statement)

            while result.next() {
                let index = result.intValue(column: Constants.columnId)
                let data = result.dataValue(column: Constants.columnLocation)

                if let data = data {
                    locations.append(
                        (index, try OpenLocateLocation(data: data))
                    )
                }
            }

        } catch let error {
            debugPrint(error.localizedDescription)
        }

        return locations
    }

    init(database: Database) {
        self.database = database
        createTableIfNotExists()
    }

    private func createTableIfNotExists() {
        let query = "CREATE TABLE IF NOT EXISTS " +
        "\(Constants.tableName) (" +
        "\(Constants.columnId) INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "\(Constants.columnLocation) BLOB NOT NULL" +
        ");"

        let statement = SQLStatement.Builder()
        .set(query: query)
        .build()

        do {
            _ = try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

final class LocationList: LocationDataSourceType {

    private var locations: [OpenLocateLocationType]

    var count: Int {
        return self.locations.count
    }

    init() {
        self.locations = [OpenLocateLocationType]()
    }

    func add(location: OpenLocateLocationType) {
        self.locations.append(location)
    }

    func addAll(locations: [OpenLocateLocationType]) {
        self.locations.append(contentsOf: locations)
    }

    func first() -> IndexedLocation? {
        if let location = self.locations.first {
            return (0, location)
        }
        return nil
    }

    func all() -> [IndexedLocation] {
        var locations = [IndexedLocation]()
        self.locations.enumerated().forEach { indexedLocation in
            locations.append(indexedLocation)
        }
        return locations
    }

    func clear() {
        self.locations.removeAll()
    }
}
