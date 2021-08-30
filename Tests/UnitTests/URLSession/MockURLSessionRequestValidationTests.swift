import Foundation
@testable import PigeonService
import XCTest

struct GetRequest: APIRequestType {
    typealias Body = EmptyBody
    typealias ResponseBody = EmptyBody

    var body = EmptyBody()
    var method: HTTPMethod {
        .get
    }
    var path: String {
        "/api/v1/oauth/login"
    }
}

struct PostRequest: APIRequestType {
    typealias Body = PickCandidateAPIModel
    typealias ResponseBody = EmptyBody

    var method: HTTPMethod {
        .post
    }
    var path: String {
        "/api/v1/order-entries/127361661/pick"
    }
    let body: Body

    init() {
        body = PickCandidateAPIModel(
            toteLabel: "PCS012",
            units: [
                PickCandidateAPIModel.UnitAPIModel(
                    barcode: "060383031527",
                    itemsAboutToExpireCount: 0,
                    pickedWeight: 0,
                    pickedQuantity: 1
                )
            ]
        )
    }
}

struct PickCandidateAPIModel: Encodable {
    let toteLabel: String
    let units: [UnitAPIModel]

    struct UnitAPIModel: Encodable {
        let barcode: String
        let itemsAboutToExpireCount: Int
        let pickedWeight: Double
        let pickedQuantity: Int

        enum CodingKeys: String, CodingKey {
            case pickedWeight
            case itemsAboutToExpireCount = "pickedQuantityWithShelfLifeException"
            case pickedQuantity
            case barcode
        }
    }

    enum CodingKeys: String, CodingKey {
        case toteLabel = "containerLabel"
        case units = "details"
    }
}

// swiftlint:disable line_length
class MockURLSessionRequestValidationTests: XCTestCase {
    var sut: MockURLSession!

    func test_RequestIsSkippedWhenRequestValidationOff() {
        sut = MockURLSession(directory: "", requestValidationMode: .none)
        let request = try! GetRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: [:],
            encoder: JSONEncoder()
        )
        let getMockDataURL = Bundle.module.url(forResource: "GET_Mock_Response_Without_Request", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: getMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_GetRequestValidationSucceedsWhenRequestValidationMatchesAll() {
        sut = MockURLSession(directory: "", requestValidationMode: .match(.all))
        let request = try! GetRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let getMockDataURL = Bundle.module.url(forResource: "GET_Mock_Response", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: getMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationSucceedsWhenRequestValidationMatchesAll() {
        sut = MockURLSession(directory: "", requestValidationMode: .match(.all))
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationFailsWhenBodyMismatches() {
        sut = MockURLSession(directory: "", requestValidationMode: .match([.matchBody]))
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response_With_Dates_In_Request", withExtension: "json")!

        XCTAssertFalse(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationSucceedsWhenRequestValidationIgnoresMismatchedBodyKeys() {
        sut = MockURLSession(directory: "", requestValidationMode: .match([.matchBodyIgnoring(keys: ["pickStartTime", "pickEndTime"])]))
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response_With_Dates_In_Request", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationFailsWhenHeaderMismatches() {
        sut = MockURLSession(directory: "", requestValidationMode: .match([.matchHeaders]))
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response_With_Dates_In_Request", withExtension: "json")!

        XCTAssertFalse(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationSucceedsWhenRequestValidationIgnoresMismatchedHeaderKeys() {
        sut = MockURLSession(directory: "", requestValidationMode: .match([.matchHeadersIgnoring(keys: ["Authorization"])]))
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response_With_Dates_In_Request", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }

    func test_PostRequestValidationSucceedsWhenRequestValidationIgnoresMismatchedHeaderKeysAndBodyKeys() {
        sut = MockURLSession(
            directory: "",
            requestValidationMode: .match(
                [
                    .matchBodyIgnoring(keys: ["pickStartTime", "pickEndTime"]),
                    .matchHeadersIgnoring(keys: ["Authorization"])
                ]
            )
        )
        let request = try! PostRequest().urlRequest(
            baseURLString: "",
            accessToken: nil,
            defaultHeaders: ["Content-Type": "application/json"],
            encoder: JSONEncoder()
        )
        let postMockDataURL = Bundle.module.url(forResource: "POST_Mock_Response_With_Dates_In_Request", withExtension: "json")!

        XCTAssertTrue(
            sut.process(
                request: request,
                mockData: try! Data(contentsOf: postMockDataURL),
                url: request.url!
            ).isSuccess
        )
    }
}

extension Result where Success == URLSessionResponse, Failure == Error {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true

        default:
            return false
        }
    }
}

// Only use this way of accessing resources if the project
// is opened through Xcode project instead of Package.swift
#if XCODE_UNIT_TEST_TARGET
private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var module: Bundle = {
        Bundle(for: BundleFinder.self)
    }()
}
#endif
