import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(SQLite_CombineTests.allTests),
    ]
}
#endif
