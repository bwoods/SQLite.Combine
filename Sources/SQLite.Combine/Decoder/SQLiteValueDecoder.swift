import Foundation
import SQLite3


struct SQLiteValueDecoder: SingleValueDecodingContainer {
	let stmt: OpaquePointer
	var column: Int32

	init(stmt: OpaquePointer, column: Int32) {
		self.stmt = stmt
		self.column = column
	}

// MARK: SingleValueDecodingContainer methods
	var codingPath: [CodingKey] = [ ]

	// these all assume the sqlite3_stmt has already been sqlite3_step()’d
	func decodeNil() -> Bool { return sqlite3_column_type(stmt, column) == SQLITE_NULL }
	func decode(_ type: Bool.Type) throws -> Bool { return Bool(sqlite3_column_int(stmt, column) != 0) }
	func decode(_ type: String.Type) throws -> String { let cString = sqlite3_column_text(stmt, column); return cString != nil ? String(cString: UnsafePointer(cString!)) : "" }
	func decode(_ type: Double.Type) throws -> Double { return sqlite3_column_double(stmt, column) }
	func decode(_ type: Float.Type) throws -> Float { return Float(sqlite3_column_double(stmt, column)) }
	func decode(_ type: Int.Type) throws -> Int { return Int(sqlite3_column_int64(stmt, column)) }
	func decode(_ type: Int8.Type) throws -> Int8 { return Int8(sqlite3_column_int(stmt, column)) }
	func decode(_ type: Int16.Type) throws -> Int16 { return Int16(sqlite3_column_int(stmt, column)) }
	func decode(_ type: Int32.Type) throws -> Int32 { return Int32(sqlite3_column_int(stmt, column)) }
	func decode(_ type: Int64.Type) throws -> Int64 { return Int64(sqlite3_column_int64(stmt, column)) }
	func decode(_ type: UInt.Type) throws -> UInt { return UInt(sqlite3_column_int64(stmt, column)) }
	func decode(_ type: UInt8.Type) throws -> UInt8 { return UInt8(sqlite3_column_int(stmt, column)) }
	func decode(_ type: UInt16.Type) throws -> UInt16 { return UInt16(sqlite3_column_int(stmt, column)) }
	func decode(_ type: UInt32.Type) throws -> UInt32 { return UInt32(sqlite3_column_int64(stmt, column)) }
	func decode(_ type: UInt64.Type) throws -> UInt64 { return UInt64(sqlite3_column_int64(stmt, column)) }

	func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		switch type {
		case is Bool.Type: return Bool(sqlite3_column_int(stmt, column) != 0) as! T
		case is String.Type: return String(cString: sqlite3_column_text(stmt, column)) as! T
		case is Double.Type: return Double(sqlite3_column_double(stmt, column)) as! T
		case is Float.Type: return Float(sqlite3_column_double(stmt, column)) as! T
		case is Int.Type: return Int(sqlite3_column_int64(stmt, column)) as! T
		case is Int8.Type: return Int8(sqlite3_column_int(stmt, column)) as! T
		case is Int16.Type: return Int16(sqlite3_column_int(stmt, column)) as! T
		case is Int32.Type: return Int32(sqlite3_column_int(stmt, column)) as! T
		case is Int64.Type: return Int64(sqlite3_column_int64(stmt, column)) as! T
		case is UInt.Type: return UInt(sqlite3_column_int64(stmt, column)) as! T
		case is UInt8.Type: return UInt8(sqlite3_column_int(stmt, column)) as! T
		case is UInt16.Type: return UInt16(sqlite3_column_int(stmt, column)) as! T
		case is UInt32.Type: return UInt32(sqlite3_column_int64(stmt, column)) as! T
		case is UInt64.Type: return UInt64(sqlite3_column_int64(stmt, column)) as! T

		case is Data.Type: return Data(bytes: sqlite3_column_blob(stmt, column), count: numericCast(sqlite3_column_bytes(stmt, column))) as! T
		case is Date.Type: return SQLiteDecoder.dateFormatter.date(from: String(cString: sqlite3_column_text(stmt, column))) as! T

		default:
			let data = Data(bytes: sqlite3_column_blob(stmt, column), count: numericCast(sqlite3_column_bytes(stmt, column)))
			return try PropertyListDecoder().decode(T.self, from: data) // we can only assume that T is string (or numeric?) constructable…
		}
	}

}


