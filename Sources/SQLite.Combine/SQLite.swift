import Foundation
import SQLite3


public final class SQLite {
	public private(set) var pointer: OpaquePointer

	static public func error(from db: OpaquePointer, _ supplemental: String = "SQLite failed") -> Error {
		NSError(domain: "sqlite", code: numericCast(sqlite3_errcode(db)), userInfo: [
			NSLocalizedFailureReasonErrorKey : String(cString: sqlite3_errmsg(db)),
			NSLocalizedFailureErrorKey : supplemental
		])
	}

// MARK: -
	private class Change {
		let dependencies: Set<String>
		let callback: () -> Void

		init( _ callback: @escaping () -> Void, dependencies: Set<String>) {
			self.dependencies = dependencies
			self.callback = callback
		}
	}

	// synchronize with SQLite’s internal locking
	func sqlite_mutex(_ block: () -> Void) {
		let mutex = sqlite3_db_mutex(pointer)
		assert(mutex != nil)

		sqlite3_mutex_enter(mutex)
		defer { sqlite3_mutex_leave(mutex) }
		block()
	}

	private var changes: Set<String> = [ ]
	private var subscribers = NSMapTable<AnyObject, Change>.weakToStrongObjects()

	func add(subscription: AnyObject, for stmt: OpaquePointer, explicit dependencies: [String]? = nil, _ callback: @escaping () -> Void) {
		let tables = Set(dependencies ?? [ ]).union(
			(0..<sqlite3_column_count(stmt)).lazy
				.compactMap { sqlite3_column_table_name(stmt, $0) } // skips “expression or subquery” columns as they are not from a table
				.map { String(cString: $0) }
		)

		assert(Thread.isMainThread) // protects the subscribers NSMapTable
		subscribers.setObject(Change(callback, dependencies: tables), forKey: subscription)
	}

	func remove(subscription: AnyObject) {
		assert(Thread.isMainThread) // protects the subscribers NSMapTable
		subscribers.removeObject(forKey: subscription)
	}


// MARK: -
	public required init(url: URL) {
		var pointer: OpaquePointer! = nil
		if sqlite3_open_v2(url.absoluteString, &pointer, SQLITE_OPEN_FULLMUTEX+SQLITE_OPEN_URI+SQLITE_OPEN_READWRITE+SQLITE_OPEN_CREATE, nil) != SQLITE_OK {
			fatalError(String(cString: sqlite3_errmsg(pointer)))
		}

		self.pointer = pointer

		let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
		sqlite3_update_hook(pointer, { (context, op, database, table, rowid) in
			let `self` = unsafeBitCast(context, to: SQLite.self)
//// We need to find a benchmark to determine if (when?) this is actually faster
//			guard self.changes.contains(where: { $0.withCString { Darwin.strcmp($0, table) != 0 } }) == false else { // we avoid constructing the String in the common case
//				return // `changes` already contains `table`
//			}

			self.changes.insert(String(cString: table!))
		}, context)

		sqlite3_rollback_hook(pointer, { context in
			let `self` = unsafeBitCast(context, to: SQLite.self)
			self.changes.removeAll() // all un-done
		}, context)

		sqlite3_commit_hook(pointer, { context -> Int32 in
			let `self` = unsafeBitCast(context, to: SQLite.self)
			DispatchQueue.main.async { [weak self] in // delay the callback until afterward (in case the callback wants to touch the database)
				if let self = self, let objectEnumerator = self.subscribers.objectEnumerator() {
					self.sqlite_mutex { // we are now in the main queue but still need to mutex with the hook’s callbacks
						for object in objectEnumerator {
							let change = object as! Change
							if self.changes.isDisjoint(with: change.dependencies) == false {
								change.callback()
							}
						}

						self.changes.removeAll() // prepare for the next batch
					}
				}
			}

			return SQLITE_OK
		}, context)
	}

	deinit {
		sqlite3_close_v2(pointer)
	}

}


extension SQLite: CustomDebugStringConvertible {
	public var debugDescription: String {
		let filename = String(cString: sqlite3_db_filename(pointer, nil))
		return "SQLite: \(filename)"
	}

}

