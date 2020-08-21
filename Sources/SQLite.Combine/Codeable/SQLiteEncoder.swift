import Foundation
import SQLite3


final public class SQLiteEncoder {
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

// MARK: -
	var column: Int = 0

	public init(_ db: SQLite, sql: String) {
		var stmt = OpaquePointer(bitPattern: 0)
		if sqlite3_prepare_v2(db.pointer, sql, -1, &stmt, nil) != SQLITE_OK {
			fatalError(String(cString: sqlite3_errmsg(db.pointer)))
		}

		self.stmt = .owned(stmt!)
	}

	init(stmt: OpaquePointer, column: Int = 0) {
		self.stmt = .unowned(stmt)
		self.column = column
	}

	deinit {
		if case let .owned(stmt) = self.stmt {
			sqlite3_finalize(stmt)
		}
	}

}


extension SQLiteEncoder : Encoder {

	public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
		KeyedEncodingContainer(SQLiteKeyed<Key>(stmt: stmt.pointer))
	}

	public func unkeyedContainer() -> UnkeyedEncodingContainer {
		SQLiteUnkeyedEncoder(stmt: stmt.pointer)
	}

	public func singleValueContainer() -> SingleValueEncodingContainer {
		SQLiteSingleValue(stmt: stmt.pointer)
	}

}

