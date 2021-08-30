import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias URLSessionResponse = (Data, HTTPURLResponse)

public protocol APIErrorResponseType: Decodable {
    var errorMessage: String { get }
    var errorCode: String { get }
}

/// `APIError` contains general errors that can occur during request construction or parsing of responses
public enum APIError: Error {
    case invalidQueryItems([URLQueryItem]?)
    case invalidURL(String)
    case responseErrorFailedToDecode(Error)
    case responseFailedWithoutErrorBody(HTTPURLResponse)
    case unauthorized
    case unknownResponseType
}

/// error expected from the API when a domain error occurs
///
/// `CustomError` is a `Decodable` type that is structured according to the error model expected from the service
public enum APIDomainError<CustomError: APIErrorResponseType>: Error {
    case responseFailedWithError(CustomError)
}

/// An interface that is used by the consumer to interact with `Pigeon` for making HTTP requests
public protocol APIServiceType {
    var accessToken: String? { get set }

    /// `baseURL` of the service the `APIServiceType` instance should point to
    var baseURLString: String { get set }

    /// `JSONDecoder` to be used for decoding `APIRequestType.ResponseBody`
    var decoder: JSONDecoder { get set }

    /// `JSONEncoder` to be used for encoding `APIRequestType.Body`
    var encoder: JSONEncoder { get set }

    /// an instance that conforms to `URLSessionType` and which will be used to make the network request
    ///
    /// `URLSession.default` can be used since it has conformance implemented in `Pigeon`
    /// pass in `MockURLSession`/`RecordURLSession` incase of mock jsons
    var urlSession: URLSessionType { get set }

	/// use this method to make a HTTP request using the passed in instance conforming to `APIRequestType`
    func send<APIRequest: APIRequestType>(
        _ apiRequest: APIRequest,
        completionHandler: @escaping (Result<APIRequest.ResponseBody, Error>) -> Void
    )
}

/// an implementation of `APIServiceType` for making HTTP network requests
public final class APIService<CustomError: APIErrorResponseType>: APIServiceType {
    // TODO: Pull out accessToken and use default headers instead [FPA-890 - Muhammad U. Ali]
    public var accessToken: String?
    public var baseURLString: String
    public var defaultHeaders: [String: String]
    public var urlSession: URLSessionType
    private var errorType: CustomError.Type
    public var decoder: JSONDecoder
    public var encoder: JSONEncoder
    public var logger: PigeonLogType?

    public init(
        baseURLString: String,
        urlSession: URLSessionType,
        errorType: CustomError.Type,
        defaultHeaders: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        logger: PigeonLogType? = nil
    ) {
        self.baseURLString = baseURLString
        self.urlSession = urlSession
        self.defaultHeaders = defaultHeaders
        self.errorType = errorType
        self.encoder = encoder
        self.decoder = decoder
        self.logger = logger
    }
    // swiftlint:disable:next function_body_length
    public func send<APIRequest: APIRequestType>(
        _ apiRequest: APIRequest,
        completionHandler: @escaping (Result<APIRequest.ResponseBody, Error>) -> Void
    ) {
        do {
            let request = try apiRequest.urlRequest(
                baseURLString: baseURLString,
                accessToken: accessToken,
                defaultHeaders: defaultHeaders,
                encoder: encoder
            )
            self.logger?.log(
                message: """
                    Request: \(request), \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "Error")
                """,
                level: .debug
            )
            let startTime = Date()
            urlSession.send(request, completionHandler: { result in
                self.logger?.log(
                    message: """
                        Completed: \(request), ResponseTime: \(Date().timeIntervalSince(startTime) * 1000) ms
                    """,
                    level: .info
                )
                switch result {
                case .success(let response):
                    let httpResponse = response.1
                    let data = response.0

                    // handle error:
                    guard httpResponse.isSuccess else {
                        let error = self.error(
                            response: httpResponse,
                            data: data,
                            errorType: self.errorType,
                            decoder: self.decoder
                        )
                        self.logger?.log(
                            message: """
                                HTTP Error: \(httpResponse.statusCode), \(error)
                            """,
                            level: .error
                        )
                        completionHandler(.failure(error))
                        return
                    }

                    // swiftlint:disable:next force_unwrapping
                    let dataToDecode = data.isEmpty ? "{}".data(using: .utf8)! : data

                    // serialize
                    do {
                        let serializedObject = try self.decoder.decode(
                            APIRequest.ResponseBody.self,
                            from: dataToDecode
                        )
                        completionHandler(.success(serializedObject))
                    } catch {
                        self.logger?.log(
                            message: """
                                Seralization Error: \(error)
                            """,
                            level: .error
                        )
                        completionHandler(.failure(error))
                    }

                case .failure(let error):
                    self.logger?.log(
                        message: """
                            Request Error: \(error)
                        """,
                        level: .error
                    )
                    return completionHandler(.failure(error))
                }
            }
            )
        } catch {
            completionHandler(.failure(error))
        }
    }

    private func error<CustomError: APIErrorResponseType>(
        response: HTTPURLResponse,
        data: Data,
        errorType: CustomError.Type,
        decoder: JSONDecoder
    ) -> Error {
        if response.statusCode == 401 { return APIError.unauthorized }
        if data.isEmpty { return APIError.responseFailedWithoutErrorBody(response) }

        do {
            let errorBody = try decoder.decode(
                errorType.self,
                from: data
            )
            return APIDomainError.responseFailedWithError(errorBody)
        } catch {
            // TODO: Remote log when this happens. [FPA-130 Sundeep G.]
            // [Slack convo](https://loblaw.slack.com/archives/GRA2GPE31/p1583509217011600)
            return APIError.responseErrorFailedToDecode(error)
        }
    }
}

/// specifies an empty/null `RequestBody` or `ResponseBody` in `APIRequestType`
public struct EmptyBody: Codable, Equatable {
    public init() { }
}
