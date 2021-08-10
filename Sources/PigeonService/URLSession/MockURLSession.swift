import Foundation

public enum MockURLSessionError: Error {
    case unableToLocateResponse(String)
    case unableToParseResponse(Data)
    case noURL
}

extension MockURLSessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unableToLocateResponse(let path):
            return "Failed to find mock response at: \(path) or the default folder"

        case .unableToParseResponse(let data):
            return "Failed to parse mock response: \(String(data: data, encoding: .utf8) ?? "")"

        case .noURL:
            return "Incoming mock request has no URL"
        }
    }
}

/// `URLSessionType` implementation used for reading mock jsons from the local file system
open class MockURLSession: URLSessionType {
    let directory: String
    public var urlCounter: [String: Int] = [:]

    /// creates an instance of `MockURLSession` that looks for the mock json files in the `directory` path
    ///
    /// - Parameter directory: a `String` value specifiying the path to the mock responses
    public init(directory: String) {
        self.directory = directory
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
            completionHandler(process(mockData: mockData, url: url))
            return
        }

        // second try, reset to 0
        urlCounter[url.path, default: -1] = 0
        if let mockData = loadJsonFromTestFolder(file: url.path) {
            completionHandler(process(mockData: mockData, url: url))
            return
        }

        // try default folder
        if let mockData = loadJsonFromDefaultFolder(file: url.path) {
            completionHandler(process(mockData: mockData, url: url))
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

    func process(mockData: Data, url: URL) -> Result<URLSessionResponse, Error> {
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
                let data = try JSONSerialization.data(withJSONObject: responseJSON, options: .prettyPrinted)
                return .success((data, urlResponse))
            }
        } catch {
            return .failure(MockURLSessionError.unableToParseResponse(mockData))
        }
        return .failure(MockURLSessionError.unableToParseResponse(mockData))
    }
}
