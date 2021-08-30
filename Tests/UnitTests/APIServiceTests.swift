import Combine
@testable import PigeonService
import XCTest

struct ServiceError: APIErrorResponseType {
    var errorMessage: String
    var errorCode: String
}

class APIServiceTests: XCTestCase {
    var sut: APIServiceType!
    var mockURLSession: MockURLSessionForTests!
    var mockAPIRequest: MockAPIRequest<FailingEncodable, TestDecodable>!
    var subscriber: Subscribers.Test<TestDecodable, Error>!

    override func setUp() {
        mockURLSession = MockURLSessionForTests()
        mockAPIRequest = MockAPIRequest(body: FailingEncodable())
        sut = APIService(
            baseURLString: "http://example.com",
            urlSession: mockURLSession,
            errorType: ServiceError.self
        )
        subscriber = Subscribers.Test()
    }

    func test_InvalidURLFails() {
        mockAPIRequest.path = "%$#*@!( *F;lw3kj4 2lk"
        sut.send(mockAPIRequest) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as! APIError, APIError.invalidURL("http://example.com%$#*@!( *F;lw3kj4 2lk"))
            } else {
                XCTFail()
            }
        }
    }

    func test_InvalidBodyFails() {
        mockAPIRequest.body = FailingEncodable()
        sut.send(mockAPIRequest) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as! TestError, TestError(message: "Test Error"))
            } else {
                XCTFail()
            }
        }
    }
}

class APIServiceAccessTokenTests: XCTestCase {
    var sut: APIServiceType!
    var mockURLSession: MockURLSessionForTests!
    var mockAPIRequest: MockAPIRequest<Int, TestDecodable>!

    override func setUp() {
        mockAPIRequest = MockAPIRequest(body: 0)
        mockURLSession = MockURLSessionForTests()
        mockURLSession.responseMap = [
            "unused_url": .success(
                (data: Data(), response: HTTPURLResponse.makeTest(statusCode: 200))
            )
        ]
        sut = APIService(
            baseURLString: "unused_url",
            urlSession: mockURLSession,
            errorType: ServiceError.self
        )
    }

    func test_NoAccessTokenDoesNotSetAuthorizationHeader() {
        sut.accessToken = nil
        sut.send(mockAPIRequest) { _ in
            XCTAssertNil(self.mockURLSession.sendRequests[0].allHTTPHeaderFields!["Authorization"])
        }
    }

    func test_AccessTokenSetsAuthorizationHeader() {
        sut.accessToken = "some-access-token"
        sut.send(mockAPIRequest) { _ in
            XCTAssertEqual(
                "Bearer some-access-token",
                self.mockURLSession.sendRequests[0].allHTTPHeaderFields!["Authorization"]
            )
        }
    }
}

class APIServiceEncoderTests: XCTestCase {
    var sut: APIService<ServiceError>!
    var mockURLSession: MockURLSessionForTests!
    var mockAPIRequest: MockAPIRequest<DateBody, TestDecodable>!

    struct DateBody: Encodable {
        let date: Date
    }

    override func setUp() {
        mockURLSession = MockURLSessionForTests()
        mockURLSession.responseMap = [
            "unused_url": .success(
                (data: Data(), response: HTTPURLResponse.makeTest(statusCode: 200))
            )
        ]
    }

    func test_PassingJSONEncoderWithCustomDateFormatAppliesDateFormatToEncodedRequestBody() {
        mockAPIRequest = MockAPIRequest(
            body: DateBody(
                date: Date.makeTest(
                    year: 2007,
                    month: 1,
                    day: 9,
                    hour: 9,
                    minute: 41,
                    calendar: Calendar(identifier: .gregorian),
                    timeZone: TimeZone(abbreviation: "EST")!
                )
            )
        )

        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        sut = APIService(
            baseURLString: "unused_url",
            urlSession: mockURLSession,
            errorType: ServiceError.self,
            encoder: encoder
        )
        sut.send(mockAPIRequest) { _ in
            XCTAssertEqual(
                String(data: self.mockURLSession.sendRequests[0].httpBody!, encoding: .utf8)!,
                "{\"date\":\"2007-01-09T09:41:00.000-05:00\"}"
            )
        }
    }
}

class APIServiceDecoderTests: XCTestCase {
    var sut: APIService<ServiceError>!
    var mockURLSession: MockURLSessionForTests!
    var mockAPIRequest: MockAPIRequest<Int, DateBody>!
    var subscriber: Subscribers.Test<DateBody, Error>!

    struct DateBody: Decodable, Equatable {
        let date: Date
    }

    override func setUp() {
        mockURLSession = MockURLSessionForTests()
        mockAPIRequest = MockAPIRequest(body: 0)
        subscriber = Subscribers.Test()
    }

    func test_PassingJSONDecoderWithCustomDateFormatAppliesDateFormatToDecodedResponseBody() {
        mockURLSession.responseMap = [
            "unused_url": .success(
                (
                    data: "{\"date\":\"2007-01-09T09:41:00.000-05:00\"}".data(using: .utf8)!,
                    response: HTTPURLResponse.makeTest(statusCode: 200)
                )
            )
        ]

        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        sut = APIService(
            baseURLString: "unused_url",
            urlSession: mockURLSession,
            errorType: ServiceError.self,
            decoder: decoder
        )

        sut.send(mockAPIRequest) { result in
            if case .success(let response) = result {
                XCTAssertEqual(
                    response,
                    DateBody(
                        date: Date.makeTest(
                            year: 2007,
                            month: 1,
                            day: 9,
                            hour: 9,
                            minute: 41,
                            calendar: Calendar(identifier: .gregorian),
                            timeZone: TimeZone(abbreviation: "EST")!
                        )
                    )
                )
            }
        }
    }
}
