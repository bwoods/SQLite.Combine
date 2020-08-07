import Foundation
import SQLite3

class SQLiteDecoder: Decoder {
	static var dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yMMddHHmmss.SSS" // see https://nsdateformatter.com
    	formatter.timeZone = TimeZone(secondsFromGMT: 0)
		return formatter
	}()

	let stmt: Statement
	enum Statement {
		case owned(OpaquePointer)
		case unowned(OpaquePointer)

		var pointer: OpaquePointer {
			switch self {
			case let .owned(stmt): return stmt
			case let .unowned(stmt): return stmt
			}
		}
	}

	func reset() {
		let stmt = self.stmt.pointer
		if sqlite3_reset(stmt) != SQLITE_OK {
			fatalError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}

		if (SQLITE_ROW...SQLITE_DONE).contains(sqlite3_step(stmt)) == false {
			fatalError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}
	}

// MARK: -
	convenience init(_ db: SQLite, sql: String) throws {
		try self.init(db, sql: sql, bindings: [ ])
	}

	convenience init(_ db: SQLite, sql: String, with values: SQLiteBindable...) throws {
		try self.init(db, sql: sql, bindings: values)
	}

	init(_ db: SQLite, sql: String, bindings values: [SQLiteBindable]) throws {
		var stmt = OpaquePointer(bitPattern: 0)
		if sqlite3_prepare_v2(db.pointer, sql, -1, &stmt, nil) != SQLITE_OK {
			fatalError(String(cString: sqlite3_errmsg(db.pointer)))
		}
		values.enumerated().forEach { $0.1.bind(stmt!, column: $0.0 + 1) }

		if (SQLITE_ROW...SQLITE_DONE).contains(sqlite3_step(stmt)) == false {
			fatalError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}

		self.stmt = .unowned(stmt!)
	}

	init(stmt: OpaquePointer) {
		self.stmt = .unowned(stmt)
	}

	deinit {
		if case let .owned(stmt) = self.stmt {
			sqlite3_finalize(stmt)
		}
	}

// MARK: - Decoder methods
	var codingPath: [CodingKey] = [ ]
	var userInfo: [CodingUserInfoKey : Any] = [ : ]

	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
		KeyedDecodingContainer(SQLiteRowDecoder<Key>(stmt: stmt.pointer))
	}

	func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		SQLiteQueryDecoder(stmt: stmt.pointer)
	}

	func singleValueContainer() throws -> SingleValueDecodingContainer {
		SQLiteValueDecoder(stmt: stmt.pointer, column: 0)
	}

}


// MARK: -

/// These constants are not properly exposed to Swift
private let SQLITE_STATIC = unsafeBitCast(OpaquePointer(bitPattern: 0), to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public protocol SQLiteBindable {
    func bind(_ stmt: OpaquePointer, column: Int)
}

extension Int: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_int64(stmt, numericCast(column), numericCast(self))
	}
}

extension Int64: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_int64(stmt, numericCast(column), numericCast(self))
	}
}

extension Double: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_double(stmt, numericCast(column), self)
	}
}

extension Float: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_double(stmt, numericCast(column), Double(self))
	}
}

extension String: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_text(stmt, numericCast(column), self, -1, SQLITE_TRANSIENT)
	}
}

extension Data: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		self.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
			sqlite3_bind_blob(stmt, numericCast(column), pointer.baseAddress!, numericCast(self.count), SQLITE_TRANSIENT)
		}
	}
}

extension Date: SQLiteBindable {
	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_double(stmt, numericCast(column), Double(SQLiteDecoder.dateFormatter.string(from: self))!)
	}
}

