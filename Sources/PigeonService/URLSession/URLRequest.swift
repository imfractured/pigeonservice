import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum URLRequestKeys: String, CodingKey {
    case httpMethod
    case path
    case headers
    case body
}

enum URLRequestError {
    case decodingRequest
}

extension URLRequestError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .decodingRequest:
            return "Error decoding URLRequest"
        }
    }
}

extension URLRequest: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: URLRequestKeys.self)
        try container.encode(httpMethod, forKey: .httpMethod)
        try container.encode(url?.path, forKey: .path)
        try container.encode(allHTTPHeaderFields, forKey: .headers)
        if let httpBody = httpBody {
            try container.encode(String(data: httpBody, encoding: .utf8), forKey: .body)
        }
    }

    public func convertToJSONObject() throws -> Any {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try JSONSerialization.jsonObject(
            with: encoder.encode(self),
            options: .mutableContainers
        )
    }
}

extension URLRequest: Decodable {
    public init(from decoder: Decoder) throws {
        guard let testURL = URL(string: "test_url") else {
            throw URLRequestError.decodingRequest
        }

        self.init(url: testURL)
        let container = try decoder.container(keyedBy: URLRequestKeys.self)
        url = try container.decode(URL.self, forKey: .path)
        httpMethod = try container.decode(String.self, forKey: .httpMethod)
        allHTTPHeaderFields = try container.decodeIfPresent(Dictionary<String, String>.self, forKey: .headers)
        if let bodyString = try container.decodeIfPresent(String.self, forKey: .body) {
            httpBody = bodyString.data(using: .utf8)
        }
    }
}

extension URLRequest {
    static func match (lhs: URLRequest, rhs: URLRequest, criteria: Set<RequestValidationMode.Criteria>) throws -> Bool {
        let pathMatch = lhs.url?.path == rhs.url?.path
        let methodMatch = lhs.httpMethod == rhs.httpMethod
        let headerMatch = try matchHTTPHeaders(
            lhs: lhs.allHTTPHeaderFields,
            rhs: rhs.allHTTPHeaderFields,
            criteria: criteria
        )
        let bodyMatch = try matchHTTPBody(
            lhs: lhs.httpBody,
            rhs: rhs.httpBody,
            criteria: criteria
        )

        return pathMatch
            && methodMatch
            && headerMatch
            && bodyMatch
    }

    private static func matchHTTPHeaders(
        lhs: [String: String]?,
        rhs: [String: String]?,
        criteria: Set<RequestValidationMode.Criteria>
    ) throws -> Bool {
        if criteria.matchHeaders {
            var lhsHeaders = lhs
            var rhsHeaders = rhs
            // Ignore keys in both headers
            criteria.forEach {
                if case .matchHeadersIgnoring(let keys) = $0 {
                    lhsHeaders = lhsHeaders?.filter { !keys.contains($0.key) }
                    rhsHeaders = rhsHeaders?.filter { !keys.contains($0.key) }
                }
            }
            return lhsHeaders == rhsHeaders
        }
        return true
    }

    private static func matchHTTPBody(
        lhs: Data?,
        rhs: Data?,
        criteria: Set<RequestValidationMode.Criteria>
    ) throws -> Bool {
        guard
            criteria.matchBody,
            let lhsDataBody = lhs ?? "{}".data(using: .utf8),
            let rhsDataBody = rhs ?? "{}".data(using: .utf8)
        else {
            return true
        }

        let lhsJSONBody = try JSONSerialization.jsonObject(with: lhsDataBody, options: .mutableContainers)
        let rhsJSONBody = try JSONSerialization.jsonObject(with: rhsDataBody, options: .mutableContainers)

        // Ignore keys in both bodies
        criteria.forEach {
            if case .matchBodyIgnoring(let keys) = $0 {
                removeAllValues(from: lhsJSONBody, for: keys)
                removeAllValues(from: rhsJSONBody, for: keys)
            }
        }

        // Making sure keys are sorted so the JSON is exact
        let lhsSortedData = try JSONSerialization.data(withJSONObject: lhsJSONBody, options: .sortedKeys)
        let rhsSortedData = try JSONSerialization.data(withJSONObject: rhsJSONBody, options: .sortedKeys)

        return lhsSortedData == rhsSortedData
    }
}

private func removeAllValues(from mutableJSON: Any, for keys: [String]) {
    for key in keys {
        (mutableJSON as? NSMutableDictionary)?.removeAllValues(for: key)
        (mutableJSON as? NSMutableArray)?.removeAllValues(for: key)
    }
}

extension NSMutableDictionary {
    func removeAllValues(for key: String) {
        self.removeObject(forKey: key)
        for (_, element) in self {
            (element as? NSMutableDictionary)?.removeAllValues(for: key)
            (element as? NSMutableArray)?.removeAllValues(for: key)
        }
    }
}

extension NSMutableArray {
    func removeAllValues(for key: String) {
        self.forEach { element in
            (element as? NSMutableDictionary)?.removeAllValues(for: key)
            (element as? NSMutableArray)?.removeAllValues(for: key)
        }
    }
}
