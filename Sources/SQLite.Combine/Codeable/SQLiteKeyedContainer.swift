import Foundation
import SQLite3


struct SQLiteKeyed<Key: CodingKey> {
	var codingPath: [CodingKey] = [ ]
	func contains(_ key: Key) -> Bool { columns[key.stringValue] != nil }
	var allKeys: [Key] { columns.keys.map { Key(stringValue: $0)! } }

	func value(for column: Int) -> SQLiteSingleValue {
		SQLiteSingleValue(stmt: stmt, column: column)
	}

	func value(for key: Key) -> SQLiteSingleValue {
		if let column = columns[key.stringValue] {
			return value(for: numericCast(column))
		}

		let expanded = sqlite3_expanded_sql(stmt); defer { sqlite3_free(expanded) }
		fatalError("‘\(key.stringValue)’ is not a column of ‘\(String(cString: sqlite3_expanded_sql(stmt)))’")
	}

// MARK: -
	let stmt: OpaquePointer
	let columns: [String : Int32]
	
	init(stmt: OpaquePointer) {
		self.stmt = stmt
		self.columns = Dictionary(uniqueKeysWithValues: (0..<sqlite3_column_count(stmt)).map { (String(cString: sqlite3_column_name(stmt, $0)), $0) })
	}

}


extension SQLiteKeyed: KeyedEncodingContainerProtocol {

	mutating func encodeNil(forKey key: Key) throws { try value(for: key).encodeNil() }
	mutating func encode(_ value: Bool, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: String, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Double, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Float, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Int, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Int8, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Int16, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Int32, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: Int64, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: UInt, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: UInt8, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: UInt16, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: UInt32, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode(_ value: UInt64, forKey key: Key) throws { try self.value(for: key).encode(value) }
	mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable { try self.value(for: key).encode(value) }

	func superEncoder() -> Encoder { SQLiteEncoder(stmt: stmt) }
	func superEncoder(forKey key: Key) -> Encoder { SQLiteEncoder(stmt: stmt) }
	func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { SQLiteUnkeyedEncoder(stmt: stmt) }
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		SQLiteEncoder(stmt: stmt).container(keyedBy: type)
	}

}


extension SQLiteKeyed: KeyedDecodingContainerProtocol {

	func decodeNil(forKey key: Key) throws -> Bool { columns[key.stringValue] == nil || value(for: key).decodeNil() }
	func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try value(for: key).decode(type) }
	func decode(_ type: String.Type, forKey key: Key) throws -> String { try value(for: key).decode(type) }
	func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try value(for: key).decode(type) }
	func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try value(for: key).decode(type) }
	func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try value(for: key).decode(type) }
	func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try value(for: key).decode(type) }
	func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try value(for: key).decode(type) }
	func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try value(for: key).decode(type) }
	func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try value(for: key).decode(type) }
	func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try value(for: key).decode(type) }
	func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try value(for: key).decode(type) }
	func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try value(for: key).decode(type) }
	func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try value(for: key).decode(type) }
	func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try value(for: key).decode(type) }
	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable { try value(for: key).decode(T.self) }

	func superDecoder() throws -> Decoder { SQLiteDecoder(stmt: stmt) }
	func superDecoder(forKey key: Key) throws -> Decoder { SQLiteDecoder(stmt: stmt) }
	func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { SQLiteUnkeyedDecoder(stmt: stmt) }
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
		try SQLiteDecoder(stmt: stmt).container(keyedBy: type)
	}

}


