import Foundation
@testable import PigeonService

class MockAPIRequest<B: Encodable, ResponseB: Decodable>: APIRequestType {
    typealias Body = B
    typealias ResponseBody = ResponseB

    var method: HTTPMethod = .get
    var path: String = ""
    var queries: [URLQueryItem]?
    var body: Body
    var headers: [String: String]?

    init(body: Body) {
        self.body = body
    }
}

struct FailingEncodable: Encodable {
    func encode(to encoder: Encoder) throws {
        throw TestError()
    }
}

struct TestDecodable: Decodable, Equatable {
    let test: Int
}

class MockURLSession: URLSessionType {
    private(set) var sendRequests: [URLRequest] = []
    var responseMap: [String: Result<URLSessionResponse, Error>]!

    func send(_ request: URLRequest, completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) {
        sendRequests.append(request)
        completionHandler(responseMap[request.url!.absoluteString]!)
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
