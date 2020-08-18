import Foundation
import SQLite3


struct SQLiteSingleValue {
	var codingPath: [CodingKey] = [ ]

// MARK: -
	let stmt: OpaquePointer
	var column: Int

	init(stmt: OpaquePointer, column: Int = 0) {
		self.stmt = stmt
		self.column = column
	}
	
}


extension SQLiteSingleValue: SingleValueEncodingContainer {

	func encodeNil() throws { sqlite3_bind_null(stmt, numericCast(column)) }
	func encode(_ value: Bool) throws  { value.bind(stmt, column: column) }
	func encode(_ value: String) throws { value.bind(stmt, column: column) }
	func encode(_ value: Double) throws { value.bind(stmt, column: column) }
	func encode(_ value: Float) throws { value.bind(stmt, column: column) }
	func encode(_ value: Int) throws { value.bind(stmt, column: column) }
	func encode(_ value: Int8) throws { Int(value).bind(stmt, column: column) }
	func encode(_ value: Int16) throws { Int(value).bind(stmt, column: column) }
	func encode(_ value: Int32) throws { Int(value).bind(stmt, column: column) }
	func encode(_ value: Int64) throws { value.bind(stmt, column: column) }
	func encode(_ value: UInt) throws { Int64(value).bind(stmt, column: column) }
	func encode(_ value: UInt8) throws { Int(value).bind(stmt, column: column) }
	func encode(_ value: UInt16) throws { Int(value).bind(stmt, column: column) }
	func encode(_ value: UInt32) throws { Int64(value).bind(stmt, column: column) }
	func encode(_ value: UInt64) throws { Int64(value).bind(stmt, column: column) }

	func encode<T>(_ value: T) throws where T : Encodable {
		switch T.self {
		case is Bool.Type: (value as! Bool).bind(stmt, column: column)
		case is String.Type: (value as! String).bind(stmt, column: column)
		case is Double.Type: (value as! Double).bind(stmt, column: column)
		case is Float.Type: (value as! Float).bind(stmt, column: column)
		case is Int.Type: (value as! Int).bind(stmt, column: column)
		case is Int8.Type: Int(value as! Int8).bind(stmt, column: column)
		case is Int16.Type: Int(value as! Int16).bind(stmt, column: column)
		case is Int32.Type: Int(value as! Int32).bind(stmt, column: column)
		case is Int64.Type: (value as! Int64).bind(stmt, column: column)
		case is UInt.Type: Int64(value as! UInt).bind(stmt, column: column)
		case is UInt8.Type: Int(value as! UInt8).bind(stmt, column: column)
		case is UInt16.Type: Int(value as! UInt16).bind(stmt, column: column)
		case is UInt32.Type: Int64(value as! UInt32).bind(stmt, column: column)
		case is UInt64.Type: Int64(value as! UInt64).bind(stmt, column: column)

		case is Data.Type: (value as! Data).bind(stmt, column: column)
		case is Date.Type: (value as! Date).bind(stmt, column: column)

		default:
			String(describing: value).bind(stmt, column: column) // will T round-trip as a String?
		}
	}

}


extension SQLiteSingleValue: SingleValueDecodingContainer {

	func decodeNil() -> Bool { return sqlite3_column_type(stmt, numericCast(column)) == SQLITE_NULL }
	func decode(_ type: Bool.Type) throws -> Bool { Bool.column(stmt, column: column) }
	func decode(_ type: String.Type) throws -> String { String.column(stmt, column: column) }
	func decode(_ type: Double.Type) throws -> Double { Double.column(stmt, column: column) }
	func decode(_ type: Float.Type) throws -> Float { Float.column(stmt, column: column) }
	func decode(_ type: Int.Type) throws -> Int { Int.column(stmt, column: column) }
	func decode(_ type: Int8.Type) throws -> Int8 { Int8(Int.column(stmt, column: column)) }
	func decode(_ type: Int16.Type) throws -> Int16 { Int16(Int.column(stmt, column: column)) }
	func decode(_ type: Int32.Type) throws -> Int32 { Int32(Int.column(stmt, column: column)) }
	func decode(_ type: Int64.Type) throws -> Int64 { Int64.column(stmt, column: column) }
	func decode(_ type: UInt.Type) throws -> UInt { UInt(Int64.column(stmt, column: column)) }
	func decode(_ type: UInt8.Type) throws -> UInt8 { UInt8(Int.column(stmt, column: column)) }
	func decode(_ type: UInt16.Type) throws -> UInt16 { UInt16(Int.column(stmt, column: column)) }
	func decode(_ type: UInt32.Type) throws -> UInt32 { UInt32(Int64.column(stmt, column: column)) }
	func decode(_ type: UInt64.Type) throws -> UInt64 { UInt64(Int64.column(stmt, column: column)) }

	func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		switch type {
		case is Bool.Type: return Bool.column(stmt, column: column) as! T
		case is String.Type: return String.column(stmt, column: column) as! T
		case is Double.Type: return Double.column(stmt, column: column) as! T
		case is Float.Type: return Float.column(stmt, column: column) as! T
		case is Int.Type: return Int.column(stmt, column: column) as! T
		case is Int8.Type: return Int.column(stmt, column: column) as! T
		case is Int16.Type: return Int.column(stmt, column: column) as! T
		case is Int32.Type: return Int64.column(stmt, column: column) as! T
		case is Int64.Type: return Int64.column(stmt, column: column) as! T
		case is UInt.Type: return Int64.column(stmt, column: column) as! T
		case is UInt8.Type: return Int.column(stmt, column: column) as! T
		case is UInt16.Type: return Int.column(stmt, column: column) as! T
		case is UInt32.Type: return Int64.column(stmt, column: column) as! T
		case is UInt64.Type: return Int64.column(stmt, column: column) as! T

		case is Data.Type: return Data.column(stmt, column: column) as! T
		case is Date.Type: return Date.column(stmt, column: column) as! T

		case is Published<Bool>.Type: return Published<Bool>(initialValue: Bool.column(stmt, column: column)) as! T
		case is Published<String>.Type: return Published<String>(initialValue: String.column(stmt, column: column)) as! T
		case is Published<Double>.Type: return Published<Double>(initialValue: Double.column(stmt, column: column)) as! T
		case is Published<Float>.Type: return Published<Float>(initialValue: Float.column(stmt, column: column)) as! T
		case is Published<Int>.Type: return Published<Int>(initialValue: Int.column(stmt, column: column)) as! T
		case is Published<Int8>.Type: return Published<Int8>(initialValue: Int8(Int.column(stmt, column: column))) as! T
		case is Published<Int16>.Type: return Published<Int16>(initialValue: Int16(Int.column(stmt, column: column))) as! T
		case is Published<Int32>.Type: return Published<Int32>(initialValue: Int32(Int.column(stmt, column: column))) as! T
		case is Published<Int64>.Type: return Published<Int64>(initialValue: Int64.column(stmt, column: column)) as! T
		case is Published<UInt>.Type: return Published<UInt>(initialValue: UInt(Int64.column(stmt, column: column))) as! T
		case is Published<UInt8>.Type: return Published<UInt8>(initialValue: UInt8(Int.column(stmt, column: column))) as! T
		case is Published<UInt16>.Type: return Published<UInt16>(initialValue: UInt16(Int.column(stmt, column: column))) as! T
		case is Published<UInt32>.Type: return Published<UInt32>(initialValue: UInt32(Int64.column(stmt, column: column))) as! T
		case is Published<UInt64>.Type: return Published<UInt64>(initialValue: UInt64(Int64.column(stmt, column: column))) as! T

		default:
			let data = Data.column(stmt, column: column)
			return try PropertyListDecoder().decode(T.self, from: data) // we can only assume that T is string (or numeric?) constructable…
		}
	}

}


// These constants are not properly exposed to Swift
private let SQLITE_STATIC = unsafeBitCast(OpaquePointer(bitPattern: 0), to: sqlite3_destructor_type.self)
private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public protocol SQLiteableValue {
    static func column(_ stmt: OpaquePointer, column: Int) -> Self
    func bind(_ stmt: OpaquePointer, column: Int)
}

extension Bool: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { Bool(sqlite3_column_int(stmt, numericCast(column)) != 0) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_int(stmt, numericCast(column), self ? 0 : 1) }
}

extension Int: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { numericCast(sqlite3_column_int64(stmt, numericCast(column))) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_int64(stmt, numericCast(column), numericCast(self)) }
}

extension Int64: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { numericCast(sqlite3_column_int64(stmt, numericCast(column))) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_int64(stmt, numericCast(column), numericCast(self)) }
}

extension Double: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { sqlite3_column_double(stmt, numericCast(column)) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_double(stmt, numericCast(column), self) }
}

extension Float: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { Float(sqlite3_column_double(stmt, numericCast(column))) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_double(stmt, numericCast(column), Double(self)) }
}

extension String: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self { String(cString: sqlite3_column_text(stmt, numericCast(column))) }
	public func bind(_ stmt: OpaquePointer, column: Int) { sqlite3_bind_text(stmt, numericCast(column), self, -1, SQLITE_TRANSIENT) }
}

extension Data: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Self {
		Data(bytes: sqlite3_column_blob(stmt, numericCast(column)), count: numericCast(sqlite3_column_bytes(stmt, numericCast(column))))
	}

	public func bind(_ stmt: OpaquePointer, column: Int) {
		self.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
			sqlite3_bind_blob(stmt, numericCast(column), pointer.baseAddress!, numericCast(self.count), SQLITE_TRANSIENT)
		}
	}
}

extension Date: SQLiteableValue {
	public static func column(_ stmt: OpaquePointer, column: Int) -> Date {
		SQLiteSingleValue.dateFormatter.date(from: String(cString: sqlite3_column_text(stmt, numericCast(column))))!
	}

	public func bind(_ stmt: OpaquePointer, column: Int) {
		sqlite3_bind_double(stmt, numericCast(column), Double(SQLiteSingleValue.dateFormatter.string(from: self))!)
	}
}

extension SQLiteSingleValue {

	fileprivate static var dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yMMddHHmmss.SSS" // see https://nsdateformatter.com
    	formatter.timeZone = TimeZone(secondsFromGMT: 0)
		return formatter
	}()

}

