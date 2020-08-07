import UIKit
import SQLite3


public extension SQLite {

	fileprivate func respond(to name: NSNotification.Name, _ block: @escaping (OpaquePointer?) -> Void) {
		NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
			let task = UIApplication.shared.beginBackgroundTask(withName: name.rawValue, expirationHandler: {
				sqlite3_interrupt(self?.pointer)
			})

			block(self?.pointer)
			UIApplication.shared.endBackgroundTask(task)
		}
	}

	fileprivate func respond(to name: NSNotification.Name, with sql: String) {
		respond(to: UIApplication.didReceiveMemoryWarningNotification) {
			db in sqlite3_exec(db, sql, nil, nil, nil)
		}
	}

	func addObservers() {
		respond(to: UIApplication.didReceiveMemoryWarningNotification) { db in sqlite3_db_release_memory(db) }
		respond(to: UIApplication.didEnterBackgroundNotification, with: "PRAGMA journal_mode=DELETE")
		respond(to: UIApplication.willEnterForegroundNotification, with: "PRAGMA journal_mode=WAL")
		respond(to: UIApplication.willTerminateNotification, with: "PRAGMA optimize")
	}

}

