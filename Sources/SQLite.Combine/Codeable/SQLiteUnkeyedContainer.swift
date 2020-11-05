import Foundation
import SQLite3


struct SQLiteUnkeyedEncoder {
	var codingPath: [CodingKey] = [ ]
	var isAtEnd: Bool { currentIndex == count }
	var currentIndex: Int = 0
	var count: Int

// MARK: -
	let stmt: OpaquePointer

	init(stmt: OpaquePointer) {
		self.stmt = stmt
		self.count = numericCast(sqlite3_bind_parameter_count(stmt))
	}

}


extension SQLiteUnkeyedEncoder: UnkeyedEncodingContainer {

	mutating func encodeNil() throws {
		try SQLiteSingleValue(stmt: stmt, column: numericCast(currentIndex)).encodeNil()
		currentIndex += 1
	}

	mutating func encode<T>(_ value: T) throws where T : Encodable {
		try SQLiteSingleValue(stmt: stmt, column: numericCast(currentIndex)).encode(value)
		currentIndex += 1
	}

	mutating func superEncoder() -> Encoder {  SQLiteEncoder(stmt: stmt) }
	mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self }
	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		SQLiteEncoder(stmt: stmt).container(keyedBy: keyType)
	}

}


struct SQLiteUnkeyedDecoder {
	var codingPath: [CodingKey] = [ ]
	var isAtEnd: Bool { status != SQLITE_ROW }
	var currentIndex: Int = 0
	var count: Int? { nil } // we never know until the query returns SQLITE_DONE

// MARK: -
	let stmt: OpaquePointer
	var status: Int32

	init(stmt: OpaquePointer) {
		self.stmt = stmt
		self.status = sqlite3_errcode(sqlite3_db_handle(stmt))
	}

}


extension SQLiteUnkeyedDecoder: UnkeyedDecodingContainer {

	mutating func decodeNil() throws -> Bool {
		let isNull = SQLiteSingleValue(stmt: stmt, column: 0).decodeNil()
		if isNull { status = sqlite3_step(stmt) }

		return isNull
	}

	mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		defer { status = sqlite3_step(stmt) }
		return try T(from: SQLiteDecoder(stmt: stmt))
	}

	func superDecoder() throws -> Decoder { SQLiteDecoder(stmt: stmt) }
	func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { self }
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
		try SQLiteDecoder(stmt: stmt).container(keyedBy: type)
	}

}

