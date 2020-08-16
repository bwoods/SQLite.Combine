import SQLite3
import Combine
import Dispatch


public extension SQLite {

	func publish<Output: Decodable>(_ sql: String, as type: Output.Type, with bindings: SQLiteableValue...) -> Publisher<Output> {
			Publisher<Output>(self, sql: sql, bindings: bindings)
	}

}

public extension SQLite {

	struct Publisher<Output: Decodable>: Combine.Publisher {
		public typealias Failure = Never
		public typealias Output = Output

		public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
			if let db = db {
				let subscription = Subscription(db, sql, bindings, subscriber, explicit: dependencies)
				subscriber.receive(subscription: subscription)
			}
		}

		/// We can not detect tables used in a subquery. Use this method to add any missing dependencies explicitly.
		/// - Parameter dependencies: a list of tables to add the SQL query’s dependencies
		func add(dependencies: String...) -> Self {
			var copy = self
			copy.dependencies = dependencies
			return copy
		}

		private let sql: String
		private let bindings: [SQLiteableValue]?
		private weak var db: SQLite?
		private var dependencies: [String]?

		fileprivate init(_ db: SQLite, sql: String, bindings: [SQLiteableValue]?) {
			self.db = db
			self.sql = sql
			self.bindings = bindings
		}
	}

}

private extension SQLite.Publisher {

	final class Subscription<S: Combine.Subscriber>: SQLiteDecoder where S.Input == Output, S.Failure == Failure {
		private var subscriber: S
		weak var db: SQLite?

		init(_ db: SQLite, _ sql: String, _ bindings: [SQLiteableValue]?, _ subscriber: S, explicit dependencies: [String]? = nil) {
			self.subscriber = subscriber
			self.db = db

			super.init(db, sql: sql, values: bindings ?? [ ])

			db.add(subscription: self, for: self.stmt.pointer, explicit: dependencies) { [weak self] in
				self?.request(Subscribers.Demand.max(1))
			}
		}
	}

}

extension SQLite.Publisher.Subscription: Combine.Subscription {

	func request(_ demand: Subscribers.Demand) {
		self.reset()
		guard let output = try? Output(from: self) else {
			return subscriber.receive(completion: .finished)
		}

		_ = subscriber.receive(output)
	}

	func cancel() {
		db?.remove(subscription: self)
	}

}

