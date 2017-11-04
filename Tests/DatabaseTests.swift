//
//  DatabaseTests.swift
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
@testable import OpenLocate

class DatabaseTests: BaseTestCase {
    private func createTableIfNotExists(in database: SQLiteDatabase) {
        let query = "CREATE TABLE IF NOT EXISTS " +
            "Location (" +
            "_id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "location BLOB NOT NULL" +
        ");"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testTestDBCreation() {
        do {
            let database = try SQLiteDatabase.testDB()
            XCTAssertNotNil(database)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testDBCreationFailure() {
        do {
            let database = try SQLiteDatabase.open(path: "temp2.db")
            XCTAssertNotNil(database)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testReadFromBD() {
        let query = "SELECT COUNT(*) FROM Location"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            let database = try SQLiteDatabase.testDB()
            createTableIfNotExists(in: database)
            let result = try database.execute(statement: statement)
            XCTAssertEqual(Int(result.intValue(column: 0)), 0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testReadFromBDFailure() {
        let query = "SELECT COUNT(*) FROM Location1"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        do {
            let database = try SQLiteDatabase.testDB()
            _ = try database.execute(statement: statement)
            XCTFail("Cannot be good. No such table in db")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
