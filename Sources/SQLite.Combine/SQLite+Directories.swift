import Foundation
import SQLite3


public extension SQLite {

	static var shared = { () -> SQLite in
		let shared = SQLite(in: .documentDirectory)
		shared.addObservers()
		return shared
	}()

	static func temporary() -> SQLite {
		var components = URLComponents()
		components.scheme = "file"

		return self.init(url: components.url!)
	}

	static func memory() -> SQLite {
		var components = URLComponents()
		components.scheme = "file"
		components.queryItems = [
			URLQueryItem(name: "mode", value: "memory")
		]

		return self.init(url: components.url!)
	}
	
	convenience init(in directory: FileManager.SearchPathDirectory) {
		let url = FileManager.default.urls(for: directory, in: .userDomainMask).first!
		let filename = url.appendingPathExtension("db").lastPathComponent.lowercased()
		let schema = url.lastPathComponent.lowercased()

		self.init(url: URL(fileURLWithPath: filename, relativeTo: url))
		upgrade(schema: schema)
	}

}

