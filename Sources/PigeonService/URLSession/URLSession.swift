import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLSessionType {
    func send(_ request: URLRequest, completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void)
}

extension URLSession: URLSessionType {
    public func send(_ request: URLRequest, completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) {
        dataTask(with: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            if let data = data, let response = response as? HTTPURLResponse {
                completionHandler(.success((data, response)))
                return
            }
            completionHandler(.failure(APIError.unknownResponseType))
        }.resume()
    }
}
