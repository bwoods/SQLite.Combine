import SwiftUI


struct SQLiteEnvironmentKey: EnvironmentKey {
    static let defaultValue: SQLite = SQLite.shared

}


public extension EnvironmentValues {

    var sqlite: SQLite {
        get {
            return self[SQLiteEnvironmentKey.self]
        }
        set {
            self[SQLiteEnvironmentKey.self] = newValue
        }
    }

}

