import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Specifies the HTTP request `method` for `APIRequestType`
public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}

/// Protocol that enforces the HTTP request specifications
public protocol APIRequestType {
    associatedtype Body: Encodable
    associatedtype ResponseBody: Decodable

    /// `Body` of the request that will be added to the request
    ///
    /// incase of a request that does not require a `Body` - set to `EmptyBody()`
    var body: Body { get }

    /// `Dictionary` that will be sent as the request headers
    ///
    /// can be used to append to/override `defaultHeaders` provided to the `APIService` instance
    /// can be set to `nil` incase no additional `headers` are needed
    var headers: [String: String]? { get }

    /// `HTTPMethod` of the request (`GET`, `POST`,`PUT` etc)
    var method: HTTPMethod { get }

    /// the `path` appended to the `baseURL` provided to the `APIService` instance
    var path: String { get }

    /// the query items to be appended to the request URL
    ///
    /// can be set to `nil` incase no query params are needed
    var queries: [URLQueryItem]? { get }

    /// the method that converts the `APIRequestType` to a `URLRequest` instance
    /// 
    /// this method can be overriden for a request incase additional modification is required to `URLRequest`
    func urlRequest(
        baseURLString: String,
        accessToken: String?,
        defaultHeaders: [String: String],
        encoder: JSONEncoder
    ) throws -> URLRequest
}

extension APIRequestType {
    func jsonEncodeBody(encoder: JSONEncoder) throws -> Data? {
        if body is EmptyBody { return nil }
        return try encoder.encode(body)
    }
}

public extension APIRequestType {
    var headers: [String: String]? { nil }
    var queries: [URLQueryItem]? { nil }

    func urlRequest(
        baseURLString: String,
        accessToken: String?,
        defaultHeaders: [String: String],
        encoder: JSONEncoder
    ) throws -> URLRequest {
        let urlString = baseURLString + path
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL(urlString)
        }

        urlComponents.queryItems = queries
        guard let url = urlComponents.url else {
            throw APIError.invalidQueryItems(urlComponents.queryItems)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = try jsonEncodeBody(encoder: encoder)
        urlRequest.httpMethod = method.rawValue

        urlRequest.allHTTPHeaderFields = defaultHeaders.merging(headers ?? [:]) { _, new in new }

        // TODO: Do we need to worry about ReservedHTTPHeaders?
        // Reasearch this: https://developer.apple.com/documentation/foundation/nsurlrequest#1776617
        if let accessToken = accessToken {
            urlRequest.allHTTPHeaderFields?["Authorization"] = "Bearer \(accessToken)"
        }

        return urlRequest
    }
}
