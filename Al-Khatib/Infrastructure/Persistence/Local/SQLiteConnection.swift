//
//  SQLiteConnection.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import SQLite3

internal let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

internal final class SQLiteConnection {
    private var db: OpaquePointer?

    internal init(path: String, readOnly: Bool = true) throws {
        let flags = readOnly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE)
        let status = sqlite3_open_v2(path, &db, flags, nil)
        if status != SQLITE_OK {
            let errMsg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            sqlite3_close(db)
            throw NSError(domain: "SQLiteConnection", code: Int(status), userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
    }

    deinit {
        sqlite3_close(db)
    }

    internal func close() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }

    internal func execute(query: String, params: [String] = []) throws -> [[String: Any]] {
        guard let db = db else {
            throw NSError(domain: "SQLiteConnection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database is closed"])
        }
        var statement: OpaquePointer?
        let status = sqlite3_prepare_v2(db, query, -1, &statement, nil)
        if status != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(db))
            throw NSError(domain: "SQLiteConnection", code: Int(status), userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        defer {
            sqlite3_finalize(statement)
        }

        for (index, param) in params.enumerated() {
            let bindStatus = sqlite3_bind_text(statement, Int32(index + 1), param, -1, SQLITE_TRANSIENT)
            if bindStatus != SQLITE_OK {
                let errMsg = String(cString: sqlite3_errmsg(db))
                throw NSError(domain: "SQLiteConnection", code: Int(bindStatus), userInfo: [NSLocalizedDescriptionKey: errMsg])
            }
        }

        var results: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, i))
                let type = sqlite3_column_type(statement, i)
                switch type {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int(statement, i))
                case SQLITE_TEXT:
                    if let textVal = sqlite3_column_text(statement, i) {
                        row[name] = String(cString: textVal)
                    } else {
                        row[name] = ""
                    }
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    if let textVal = sqlite3_column_text(statement, i) {
                        row[name] = String(cString: textVal)
                    } else {
                        row[name] = nil
                    }
                }
            }
            results.append(row)
        }
        return results
    }

    internal func stringQuery(query: String, params: [String] = []) -> String? {
        do {
            let results = try execute(query: query, params: params)
            guard let first = results.first, let val = first.values.first else { return nil }
            if val is NSNull { return nil }
            return val as? String ?? "\(val)"
        } catch {
            return nil
        }
    }

    internal func intQuery(query: String, params: [String] = []) -> Int {
        do {
            let results = try execute(query: query, params: params)
            guard let first = results.first, let val = first.values.first else { return 0 }
            if val is NSNull { return 0 }
            return val as? Int ?? Int("\(val)") ?? 0
        } catch {
            return 0
        }
    }

    internal func intQueryOrNull(query: String, params: [String] = []) -> Int? {
        do {
            let results = try execute(query: query, params: params)
            guard let first = results.first, let val = first.values.first else { return nil }
            if val is NSNull { return nil }
            return val as? Int ?? Int("\(val)")
        } catch {
            return nil
        }
    }
}
