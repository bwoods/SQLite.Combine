import Foundation
import SQLite3


public class SQLiteDecoder {
	public var codingPath: [CodingKey] = [ ]
	public var userInfo: [CodingUserInfoKey : Any] = [ : ]

	let stmt: Statement
	enum Statement {
		case owned(OpaquePointer)
		case unowned(OpaquePointer)

		var pointer: OpaquePointer {
			switch self {
			case let .owned(stmt):
				return stmt
			case let .unowned(stmt):
				return stmt
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
	public convenience init(_ db: SQLite, sql: String) {
		self.init(db, sql: sql, values: [ ])
	}

	public convenience init(_ db: SQLite, sql: String, with bindings: SQLiteableValue...) {
		self.init(db, sql: sql, values: bindings)
	}

	public init(_ db: SQLite, sql: String, values bindings: [SQLiteableValue]) {
		var stmt = OpaquePointer(bitPattern: 0)
		if sqlite3_prepare_v2(db.pointer, sql, -1, &stmt, nil) != SQLITE_OK {
			fatalError(String(cString: sqlite3_errmsg(db.pointer)))
		}

		bindings.enumerated().forEach { $0.1.bind(stmt!, column: $0.0 + 1) }

		if (SQLITE_ROW...SQLITE_DONE).contains(sqlite3_step(stmt)) == false {
			fatalError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}

		self.stmt = .owned(stmt!)
	}

	init(stmt: OpaquePointer) {
		self.stmt = .unowned(stmt)
	}

	deinit {
		if case let .owned(stmt) = self.stmt {
			sqlite3_finalize(stmt)
		}
	}

}


extension SQLiteDecoder: Decoder {

	public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
		KeyedDecodingContainer(SQLiteKeyed<Key>(stmt: stmt.pointer))
	}

	public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		SQLiteUnkeyedDecoder(stmt: stmt.pointer)
	}

	public func singleValueContainer() throws -> SingleValueDecodingContainer {
		SQLiteSingleValue(stmt: stmt.pointer, column: 0)
	}

}


extension SQLite {

	public func sql(_ sql: String, with bindings: SQLiteableValue...) {
		_ = SQLiteDecoder(self, sql: sql, values: bindings)
	}

	public func decode<R: Decodable>(sql: String, with bindings: SQLiteableValue...) -> R {
		try! R(from: SQLiteDecoder(self, sql: sql, values: bindings))
	}

}

