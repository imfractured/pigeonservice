import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import PigeonService
import XCTest

class APIRequestJSONEncodedBodyTests: XCTestCase {
    func test_EmptyBodyReturnsNil() {
        let sut = MockAPIRequest<EmptyBody, EmptyBody>(body: EmptyBody())
        XCTAssertNil(try! sut.jsonEncodeBody(encoder: JSONEncoder()))
    }

    func test_NonEmptyBodyReturnsData() {
        let sut = MockAPIRequest<Int, EmptyBody>(body: 123)
        XCTAssertFalse(try! sut.jsonEncodeBody(encoder: JSONEncoder())!.isEmpty)
    }

    func test_NonEmptyBodyAndNonEncodableBodyFails() {
        let sut = MockAPIRequest<Float, EmptyBody>(body: unencodableFloat)
        XCTAssertThrowsError(try sut.jsonEncodeBody(encoder: JSONEncoder()))
    }

    func test_DateEncodesToISO8601FormatAndESTTimeZone() {
        let body = Date.makeTest(
            year: 2020,
            month: 06,
            day: 29,
            hour: 10,
            minute: 00,
            timeZone: TimeZone(identifier: "America/Halifax")!
        )
        let format = DateFormatter()
        format.timeZone = .current
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        let dateString = format.string(from: body)

        let sut = MockAPIRequest<Date, EmptyBody>(body: body)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(format)
        let result = String(data: try! sut.jsonEncodeBody(encoder: encoder)!, encoding: .utf8)!
        XCTAssertEqual("\"\(dateString)\"", result)
    }
}

class APIRequestToURLRequestTests: XCTestCase {
    var sut: MockAPIRequest<EmptyBody, EmptyBody>!

    override func setUp() {
        sut = MockAPIRequest(body: EmptyBody())
    }

    func test_HeadersReturnsAPIRequestHeadersWhenNoDefaultHeadersPassedIn() {
        sut = MockAPIRequest(body: EmptyBody())
        sut.headers = [
            "Content-Type": "application/json",
            "version": "abc"
        ]
        let urlRequest = try! sut.urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: [:],
            encoder: JSONEncoder()
        )
        XCTAssertEqual(
            urlRequest.allHTTPHeaderFields,
            [
                "Content-Type": "application/json",
                "version": "abc"
            ]
        )
    }

    func test_HeadersReturnsAPIRequestHeadersAndDefaultHeadersWhenDefaultHeadersPassedIn() {
        sut = MockAPIRequest(body: EmptyBody())
        sut.headers = [
            "Content-Type": "application/json",
            "version": "abc"
        ]
        let urlRequest = try! sut.urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Language": "en-us"],
            encoder: JSONEncoder()
        )
        XCTAssertEqual(
            urlRequest.allHTTPHeaderFields,
            [
                "Language": "en-us",
                "Content-Type": "application/json",
                "version": "abc"
            ]
        )
    }

    func test_HeadersReturnsOverridenAPIRequestHeadersWhenSameKeyPresentInBothAPIRequestHeadersAndDefaultHeaders() {
        sut = MockAPIRequest(body: EmptyBody())
        sut.headers = [
            "Content-Type": "application/json",
            "version": "11.0"
        ]
        let urlRequest = try! sut.urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["version": "10.0", "Language": "en-us"],
            encoder: JSONEncoder()
        )
        XCTAssertEqual(
            urlRequest.allHTTPHeaderFields,
            [
                "Language": "en-us",
                "Content-Type": "application/json",
                "version": "11.0"
            ]
        )
    }
}

extension Date {
    static func makeTest(
        year: Int = 2007,
        month: Int = 1,
        day: Int = 9,
        hour: Int = 9,
        minute: Int = 41,
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone.current
    ) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
