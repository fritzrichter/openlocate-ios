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

typealias NextBlockCompletion = (_ hasAnotherRow: Bool) -> Void

protocol Result {
    func next(block: NextBlockCompletion?)
    func reset() -> Bool

    func intValue(column: Int) -> Int
    func intValue(column: String) -> Int
    func dataValue(column: String) -> Data?
}

final class SQLResult: Result {
    let statement: OpaquePointer

    private let connectionQueue: DispatchQueue?
    private let executeQueue: DispatchQueue?

    private lazy var columnCount: Int = Int(sqlite3_column_count(statement))
    private lazy var columnNames: [String] = (0..<CInt(columnCount)).map {
        String(cString: sqlite3_column_name(statement, $0))
    }

    fileprivate init(statement: OpaquePointer, connectionQueue: DispatchQueue?, executeQueue: DispatchQueue?) {
        self.statement = statement
        self.connectionQueue = connectionQueue
        self.executeQueue = executeQueue
    }

    deinit {
        sqlite3_finalize(statement)
    }
}

extension SQLResult {

    final class Builder {
        var statement: OpaquePointer?
        var connectionQueue: DispatchQueue?
        var executeQueue: DispatchQueue?

        func set(statement: OpaquePointer?) -> Builder {
            self.statement = statement

            return self
        }

        func set(connectionQueue: DispatchQueue?) -> Builder {
            self.connectionQueue = connectionQueue

            return self
        }

        func set(executeQueue: DispatchQueue?) -> Builder {
            self.executeQueue = executeQueue

            return self
        }

        func build() -> SQLResult {
            return SQLResult(statement: statement!, connectionQueue: connectionQueue, executeQueue: executeQueue)
        }
    }
}

extension SQLResult {

    func intValue(column: Int) -> Int {
        return Int(
            sqlite3_column_int(
                statement,
                CInt(column)
            )
        )
    }

    func intValue(column: String) -> Int {
        return intValue(column: columnNames.index(of: column)!)
    }

    func dataValue(column: String) -> Data? {
        let index = CInt(columnNames.index(of: column)!)

        let size = sqlite3_column_bytes(statement, index)
        let buffer = sqlite3_column_blob(statement, index)
        guard let buf = buffer else {
            return nil
        }

        return Data(bytes: buf, count: Int(size))
    }
}

extension SQLResult {

    func next(block: NextBlockCompletion?) {
        guard let queue = executeQueue else {
            let hasAnotherRow = step() == SQLITE_ROW
            block?(hasAnotherRow)

            return
        }

        queue.async { [weak self] in
            guard let strongSelf = self else { return }

            let hasAnotherRow = strongSelf.step() == SQLITE_ROW

            block?(hasAnotherRow)
        }
    }

    @discardableResult
    func reset() -> Bool {
        let result = sync { () -> Int32 in
            sqlite3_reset(statement)
        }

        return result == SQLITE_DONE || result == SQLITE_OK
    }

    private func step() -> CInt {
        return sync({ () -> CInt in
            sqlite3_step(statement)
        })
    }

    func code(block: @escaping (_ code: CInt) -> Void) {
        guard let queue = executeQueue else {
            let resultCode = step()
            reset()

            block(resultCode)

            return
        }

        queue.async { [weak self] in
            guard let strongSelf = self else { return }

            let resultCode = strongSelf.step()
            strongSelf.reset()

            block(resultCode)
        }
    }

    private func sync<T>(_ block: () throws -> T) rethrows -> T {
        guard let queue = connectionQueue else {
            return try block()
        }

        return try queue.sync(execute: block)
    }

    private func async<T>(_ block: @escaping () throws -> T,
                          _ resultBlock: @escaping (T) -> Void,
                          _ errorBlock: @escaping (Error) -> Void) {
        guard let queue = executeQueue else {
            performThrowableBlock(block, resultBlock, errorBlock)

            return
        }

        queue.async {
            self.performThrowableBlock(block, resultBlock, errorBlock)
        }
    }

    private func performThrowableBlock<T>(_ block: @escaping () throws -> T,
                                          _ resultBlock: @escaping (T) -> Void,
                                          _ errorBlock: @escaping (Error) -> Void) {
        do {
            resultBlock(try block())
        } catch {
            errorBlock(error)
        }
    }
}
