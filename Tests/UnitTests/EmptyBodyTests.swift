@testable import PigeonService
import XCTest

class EmptyBodyDecodingTests: XCTestCase {
    func test_JSONObjectWithFieldsDecodesToEmptyBody() {
        let data = "{ \"emptyBody\": false }".data(using: .utf8)!
        let result = try! JSONDecoder().decode(EmptyBody.self, from: data)
        XCTAssertEqual(result, EmptyBody())
    }

    func test_JSONArrayDecodesToEmptyBody() {
        let data = "[123, 456]".data(using: .utf8)!
        let result = try! JSONDecoder().decode(EmptyBody.self, from: data)
        XCTAssertEqual(result, EmptyBody())
    }

    func test_JSONPrimitiveDecodesToEmptyBody() {
        let data = "99".data(using: .utf8)!
        let result = try! JSONDecoder().decode(EmptyBody.self, from: data)
        XCTAssertEqual(result, EmptyBody())
    }

    func test_JSONNullDecodesToEmptyBody() {
        let data = "null".data(using: .utf8)!
        let result = try! JSONDecoder().decode(EmptyBody.self, from: data)
        XCTAssertEqual(result, EmptyBody())
    }
}
