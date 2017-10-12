//
//  Database.swift
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
import SQLite3

enum SQLiteError: Error {
    case open(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
}

protocol Database {
    func execute(statement: Statement, completion: ExecuteCompletion?) throws
    func begin()
    func commit()
    func rollback()
}

final class SQLiteDatabase: Database {
    fileprivate enum Constants {
        static let databaseName = "safagraph.sqlite3"
    }

    fileprivate enum Queue {
        static let connectionQueue = "safagraph.sqlite3.connectionQueue"
        static let executionQueue = "safagraph.sqlite3.executionQueue"
    }

    private let sqliteTransient = unsafeBitCast(-1, to:sqlite3_destructor_type.self)

    private let connectionQueue = DispatchQueue(label: Queue.connectionQueue, attributes: [])
    private let executionQueue = DispatchQueue(label: Queue.executionQueue, attributes: [])

    private let database: OpaquePointer
    private let fmt = DateFormatter()

    private init(database: OpaquePointer) {
        self.database = database
    }

    deinit {
        sqlite3_close(database)
    }

    private var errorMessage: String {
        return String(cString:sqlite3_errmsg(database))
    }
}

extension SQLiteDatabase {

    static func openLocateDatabase() throws -> SQLiteDatabase {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let url = URL(string: path) else {

            throw SQLiteError.open(message: "Error getting directory")
        }

        return try open(path: url.appendingPathComponent(Constants.databaseName).path)
    }

    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?

        if sqlite3_open(path, &db) == SQLITE_OK, let db = db {
            setupDatabaseFileProtection(.none, atPath: path)

            return SQLiteDatabase(database: db)
        } else {
            let message: String

            if let database = db {
                defer {
                    sqlite3_close(database)
                }
                message = String(cString: sqlite3_errmsg(database))
            } else {
                message = "Error opening database"
            }

            throw SQLiteError.open(message: message)
        }
    }

    private static func setupDatabaseFileProtection(_ protection: FileProtectionType, atPath path: String) {
        do {
            try FileManager.default.setAttributes([FileAttributeKey.protectionKey: protection],
                                                  ofItemAtPath: path)
        } catch {
            debugPrint(error)
        }
    }

    private func prepareStatement(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
            let preparedStatement = statement else {
            throw SQLiteError.prepare(message: errorMessage)
        }

        return preparedStatement
    }

    private func bindParameter(_ statement: inout OpaquePointer, args: StatementArgs) throws {
        let queryCount = sqlite3_bind_parameter_count(statement)

        if queryCount != args.count {
            throw SQLiteError.bind(message: errorMessage)
        }

        args.enumerated().forEach { index, object in
            _ = bindObject(
                object: object,
                column: index + 1,
                statement: &statement
            )
        }
    }

    private func bindObject(object: Any, column: Int, statement: inout OpaquePointer) -> CInt {
        let flag: CInt

        if let txt = object as? String {
            flag = sqlite3_bind_text(statement, CInt(column), txt, -1, sqliteTransient)
        } else if let data = object as? NSData {
            flag = sqlite3_bind_blob(statement, CInt(column), data.bytes, CInt(data.length), sqliteTransient)
        } else if let date = object as? Date {
            let txt = fmt.string(from:date)
            flag = sqlite3_bind_text(statement, CInt(column), txt, -1, sqliteTransient)
        } else if let val = object as? Bool {
            let num = val ? 1 : 0
            flag = sqlite3_bind_int(statement, CInt(column), CInt(num))
        } else if let val = object as? Double {
            flag = sqlite3_bind_double(statement, CInt(column), CDouble(val))
        } else if let val = object as? Int {
            flag = sqlite3_bind_int(statement, CInt(column), CInt(val))
        } else {
            flag = sqlite3_bind_null(statement, CInt(column))
        }

        return flag
    }
}

typealias ExecuteCompletion = (_ result: Result, _ error: Error?) -> Void

extension SQLiteDatabase {
    func execute(statement: Statement, completion: ExecuteCompletion?) throws {
        var preparedStatement = try connectionQueue.sync { () -> OpaquePointer in
            try prepareStatement(statement.statement)
        }

        try connectionQueue.sync(execute: { () -> Void in
            try bindParameter(&preparedStatement, args: statement.args)
        })

        let result = SQLResult.Builder()
            .set(statement: preparedStatement)
            .set(connectionQueue: connectionQueue)
            .set(executeQueue: executionQueue)
            .build()

        if !statement.cached {
            result.code { [weak self] (code) in
                do {
                    try self?.checkResult(code)
                    completion?(result, nil)
                } catch {
                    completion?(result, error)
                }
            }
        } else {
            completion?(result, nil)
        }
    }

    private func checkResult(_ code: CInt) throws {
        switch code {
        case SQLITE_DONE, SQLITE_OK:
            break
        case SQLITE_ROW:
            throw SQLiteError.step(message: errorMessage)
        case SQLITE_CONSTRAINT:
            throw SQLiteError.step(message: errorMessage)
        default:
            throw SQLiteError.step(message: "SQL error")
        }
    }
}

extension SQLiteDatabase {
    func begin() {
        let query = "BEGIN EXCLUSIVE"
        let statement = SQLStatement.Builder()
        .set(query: query)
        .build()

        try? execute(statement: statement, completion: nil)
    }

    func commit() {
        let query = "COMMIT"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        try? execute(statement: statement, completion: nil)
    }

    func rollback() {
        let query = "ROLLBACK"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        try? execute(statement: statement, completion: nil)
    }
}
