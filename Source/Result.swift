//
//  Result.swift
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

protocol Result {
    func next() -> Bool
    func reset() -> Bool

    func intValue(column: Int) -> Int
    func intValue(column: String) -> Int
    func dataValue(column: String) -> Data?
}

final class SQLResult: Result {
    let statement: OpaquePointer

    private let queue: DispatchQueue?

    private lazy var columnCount: Int = Int(sqlite3_column_count(statement))
    private lazy var columnNames: [String] = (0..<CInt(columnCount)).map {
        String(cString: sqlite3_column_name(statement, $0))
    }

    fileprivate init(statement: OpaquePointer, queue: DispatchQueue?) {
        self.statement = statement
        self.queue = queue
    }

    deinit {
        sync { sqlite3_finalize(statement) }
    }
}

extension SQLResult {

    final class Builder {
        var statement: OpaquePointer?
        var queue: DispatchQueue?

        func set(statement: OpaquePointer?) -> Builder {
            self.statement = statement

            return self
        }

        func set(queue: DispatchQueue?) -> Builder {
            self.queue = queue

            return self
        }

        func build() -> SQLResult {
            return SQLResult(statement: statement!, queue: queue)
        }
    }
}

extension SQLResult {

    func intValue(column: Int) -> Int {
        return sync {
            return Int(sqlite3_column_int(statement, CInt(column)))
        }
    }

    func intValue(column: String) -> Int {
        return intValue(column: columnNames.index(of: column)!)
    }

    func dataValue(column: String) -> Data? {
        return sync {
            let index = CInt(columnNames.index(of: column)!)

            let size = sqlite3_column_bytes(statement, index)
            let buffer = sqlite3_column_blob(statement, index)
            guard let buf = buffer else {
                return nil
            }

            return Data(bytes: buf, count: Int(size))
        }
    }
}

extension SQLResult {

    func next() -> Bool {
        return step() == SQLITE_ROW
    }

    func reset() -> Bool {
        return sync {
            let result = sqlite3_reset(statement)
            return result == SQLITE_DONE || result == SQLITE_OK
        }
    }

    private func step() -> CInt {
        return sync { sqlite3_step(statement) }
    }

    var code: CInt {
        let resultCode = step()
        _ = reset()

        return resultCode
    }
}

extension SQLResult {
    @discardableResult
    func sync<ReturnType>(block: () -> ReturnType) -> ReturnType {
        guard let queue = queue else {
            return block()
        }

        return queue.sync { () -> ReturnType in
            block()
        }
    }
}
