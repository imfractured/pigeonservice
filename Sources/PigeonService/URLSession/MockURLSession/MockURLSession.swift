import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// `URLSessionType` implementation used for reading mock jsons from the local file system
open class MockURLSession: URLSessionType {
    let directory: String
    let requestValidationMode: RequestValidationMode
    public var urlCounter: [String: Int] = [:]

    /// creates an instance of `MockURLSession` that looks for the mock json files in the `directory` path
    ///
    /// - Parameter directory: a `String` value specifiying the path to the mock responses
    /// - Parameter requestValidationMode: a `RequestValidationMode` value specifying mode of validation
    public init(directory: String, requestValidationMode: RequestValidationMode = .none) {
        self.directory = directory
        self.requestValidationMode = requestValidationMode
    }

    open func loadJsonFromTestFolder(file: String) -> Data? {
        let filename = file.replacingOccurrences(of: "/", with: ":")
        if
            let count = urlCounter[file],
            let url = URL(string: directory + "/" + filename + "/" + "\(String(describing: count))" + ".json")
        {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    open func loadJsonFromDefaultFolder(file: String) -> Data? {
        let filename = file.replacingOccurrences(of: "/", with: ":")
        if
            let defaultPath = ProcessInfo.processInfo.environment["mock_responses"],
            let url = URL(string: defaultPath + "default/" + filename + ".json")
        {
            return try? Data(contentsOf: url)
        }
        return nil
    }
    public func send(_ request: URLRequest, completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) {
        guard let url = request.url else {
            completionHandler(.failure(MockURLSessionError.noURL))
            return
        }

        // try by incrementing
        urlCounter[url.path, default: -1] += 1
        if let mockData = loadJsonFromTestFolder(file: url.path) {
            completionHandler(process(request: request, mockData: mockData, url: url))
            return
        }

        // second try, reset to 0
        urlCounter[url.path, default: -1] = 0
        if let mockData = loadJsonFromTestFolder(file: url.path) {
            completionHandler(process(request: request, mockData: mockData, url: url))
            return
        }

        // try default folder
        if let mockData = loadJsonFromDefaultFolder(file: url.path) {
            completionHandler(process(request: request, mockData: mockData, url: url))
            return
        }

        completionHandler(
            .failure(
                MockURLSessionError.unableToLocateResponse(
                    self.directory + url.path + "/\(String(describing: urlCounter[url.path] ?? 0)).json"
                )
            )
        )
    }

    func process(request: URLRequest, mockData: Data, url: URL) -> Result<URLSessionResponse, Error> {
        do {
            if
                let body = try JSONSerialization.jsonObject(with: mockData) as? [String: Any],
                let statusCode = body["status"] as? Int,
                let responseJSON = body["response"],
                JSONSerialization.isValidJSONObject(responseJSON),
                let urlResponse = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "1.1",
                    headerFields: nil
                ) {
                // Validate request object
                if case .match(let criteria) = requestValidationMode {
                    do {
                        guard let requestJSON = body["request"] else {
                            throw MockURLSessionError.mockRequestNotFound(request)
                        }

                        let data = try JSONSerialization.data(withJSONObject: requestJSON, options: .prettyPrinted)
                        let mockRequest = try JSONDecoder().decode(URLRequest.self, from: data)
                        if try URLRequest.match(lhs: mockRequest, rhs: request, criteria: criteria) == false {
                            return .failure(MockURLSessionError.requestValidationFailed(request))
                        }
                    } catch {
                        return .failure(error)
                    }
                }

                let data = try JSONSerialization.data(withJSONObject: responseJSON, options: .prettyPrinted)
                return .success((data, urlResponse))
            }
        } catch {
            return .failure(MockURLSessionError.unableToParseResponse(mockData))
        }
        return .failure(MockURLSessionError.unableToParseResponse(mockData))
    }
}
