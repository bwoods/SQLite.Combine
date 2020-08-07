import Foundation
import SQLite3


struct SQLiteRowDecoder<Key: CodingKey>: KeyedDecodingContainerProtocol {
	let stmt: OpaquePointer
	let columns: [String : Int32]

	init(stmt: OpaquePointer) {
		self.stmt = stmt
		self.columns = Dictionary(uniqueKeysWithValues: (0..<sqlite3_column_count(stmt)).map { (String(cString: sqlite3_column_name(stmt, $0)), $0) })
	}

	func decoder(for column: Int32) -> SQLiteValueDecoder {
		return SQLiteValueDecoder(stmt: stmt, column: column)
	}

	func decoder(for key: Key) -> SQLiteValueDecoder {
		if let column = columns[key.stringValue] {
			return decoder(for: column)
		}

		let expanded = sqlite3_expanded_sql(stmt); defer { sqlite3_free(expanded) }
		fatalError("‘\(key.stringValue)’ is not a column of ‘\(String(cString: sqlite3_expanded_sql(stmt)))’")
	}


// MARK: -
	func contains(_ key: Key) -> Bool { return columns[key.stringValue] != nil }
	var allKeys: [Key] { return columns.keys.map { Key(stringValue: $0)! } }
	var codingPath: [CodingKey] = [ ]

	// these all assume the sqlite3_stmt has already been sqlite3_step()’d
	func decodeNil(forKey key: Key) throws -> Bool { return columns[key.stringValue] == nil || decoder(for: key).decodeNil() }
	func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try decoder(for: key).decode(type) }
	func decode(_ type: String.Type, forKey key: Key) throws -> String { try decoder(for: key).decode(type) }
	func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try decoder(for: key).decode(type) }
	func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try decoder(for: key).decode(type) }
	func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try decoder(for: key).decode(type) }
	func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try decoder(for: key).decode(type) }
	func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try decoder(for: key).decode(type) }
	func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try decoder(for: key).decode(type) }
	func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try decoder(for: key).decode(type) }
	func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try decoder(for: key).decode(type) }
	func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try decoder(for: key).decode(type) }
	func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try decoder(for: key).decode(type) }
	func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try decoder(for: key).decode(type) }
	func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try decoder(for: key).decode(type) }
	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable { try decoder(for: key).decode(T.self) }

	func superDecoder() throws -> Decoder { SQLiteDecoder(stmt: stmt) }
	func superDecoder(forKey key: Key) throws -> Decoder { SQLiteDecoder(stmt: stmt) }
	func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { SQLiteQueryDecoder(stmt: stmt) }
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
		try SQLiteDecoder(stmt: stmt).container(keyedBy: type)
	}
}


