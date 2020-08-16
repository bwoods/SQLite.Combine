import XCTest
import SQLite3
@testable import SQLite_Combine


class SQLite_CombineTests: XCTestCase {
	func testCompilationOptions() {
		let options = Set<String>(
			(0...).lazy
				.prefix { sqlite3_compileoption_get(numericCast($0)) != nil }
				.map { sqlite3_compileoption_get(numericCast($0)) }
				.map { String(cString: $0) }
		)

		XCTAssertTrue(options.contains("USE_URI"))
		XCTAssertTrue(options.contains("ENABLE_COLUMN_METADATA"))

		XCTAssertFalse(options.contains("DEFAULT_SYNCHRONOUS=0"))
		XCTAssertFalse(sqlite3_threadsafe() == 0)
	}


    func testSQLiteDecoder() throws {
        let db = SQLite.temporary()

		var tables = try! [String](from: SQLiteDecoder(db, sql: "SELECT name FROM sqlite_master WHERE type == 'table'"))
		XCTAssertTrue(tables.isEmpty)

		let status = sqlite3_exec(db.pointer, "CREATE TABLE 'check' (id INTEGER PRIMARY KEY)", nil, nil, nil)
		XCTAssertEqual(status, SQLITE_OK, String(cString: sqlite3_errmsg(db.pointer)))

		tables = try! [String](from: SQLiteDecoder(db, sql: "SELECT name FROM sqlite_master WHERE type == 'table'"))
		XCTAssertFalse(tables.isEmpty)
		XCTAssertTrue(tables.count == 1)
		XCTAssertEqual(tables.first!, "check")
    }

}

