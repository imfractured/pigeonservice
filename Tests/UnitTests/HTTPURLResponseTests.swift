@testable import PigeonService
import XCTest

class HTTPURLResponseTests: XCTestCase {
    func test_StatusCodeWithin200RangeIsSuccess() {
        XCTAssertTrue(HTTPURLResponse.makeTest(statusCode: 200).isSuccess)
        XCTAssertTrue(HTTPURLResponse.makeTest(statusCode: 250).isSuccess)
        XCTAssertTrue(HTTPURLResponse.makeTest(statusCode: 299).isSuccess)
    }

    func test_StatusCodeOutIF200RangeIsNotSuccess() {
        XCTAssertFalse(HTTPURLResponse.makeTest(statusCode: 199).isSuccess)
        XCTAssertFalse(HTTPURLResponse.makeTest(statusCode: 300).isSuccess)
        XCTAssertFalse(HTTPURLResponse.makeTest(statusCode: 400).isSuccess)
        XCTAssertFalse(HTTPURLResponse.makeTest(statusCode: 500).isSuccess)
    }
}

extension HTTPURLResponse {
    static func makeTest(
        url: URL = URL(string: "www.example.com")!,
        statusCode: Int = 200,
        httpVersion: String? = nil,
        headerFields: [String: String]? = nil
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: httpVersion,
            headerFields: headerFields
        )!
    }
}
