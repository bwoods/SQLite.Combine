import SQLite3
#if os(macOS)
import AppKit.NSDataAsset
#elseif os(iOS)
import UIKit.NSDataAsset
#endif

public extension SQLite {

	func upgrade(schema prefix: String) {
		// re-establish defaults
		sqlite3_exec(pointer, "PRAGMA cache_size = 10240", nil, nil, nil) // 10240 × 4 KiB page_size → 40 MiB page cache
		sqlite3_exec(pointer, "PRAGMA journal_mode=WAL", nil, nil, nil) // must come before the PRAGMA user_version for (some reason) or it has no effect

		var version = try! Int(from: SQLiteDecoder(self, sql: "PRAGMA user_version"))

		if version > 0 && NSDataAsset(name: "\(prefix).v\(version)") == nil {
			// TODO: take an error block (default to this…) allow database reset for fully re-downloadable data
			fatalError("Database is of a newer file format ‘v\(version)’ than this application version (\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "????")) supports")
		}

		version += 1 // run any update scripts beyond the current version number
		sqlite3_exec(pointer, "BEGIN TRANSACTION", nil, nil, nil)

		let execute = { (pointer: OpaquePointer, sql: String) in
			var msg = UnsafeMutablePointer<Int8>(bitPattern: 0)
			if sqlite3_exec(pointer, sql, nil, nil, &msg) != SQLITE_OK {
				sqlite3_exec(pointer, "ROLLBACK TRANSACTION", nil, nil, nil) // explicitly cleanup the database; not needed, but nice to do
				fatalError(msg != nil ? String(cString: msg!) : "Unknown error")
			}
		}

		for n in version... {
			guard let asset = NSDataAsset(name: "\(prefix).v\(n)"), let sql = String(data: asset.data, encoding: .utf8) else {
				break
			}

			assert(sql.contains("PRAGMA user_version = \(n);"))
			execute(pointer, sql)
		}

		if let asset = NSDataAsset(name: "\(prefix).temporary"), let sql = String(data: asset.data, encoding: .utf8) {
			execute(pointer, sql) // temporary tables/views that need (re)creating every time — if any
		}

		sqlite3_exec(pointer, "COMMIT TRANSACTION", nil, nil, nil)
	}

}


