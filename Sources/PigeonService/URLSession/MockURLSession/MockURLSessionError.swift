import Foundation

public enum MockURLSessionError: Error {
    case unableToLocateResponse(String)
    case unableToParseResponse(Data)
    case mockRequestNotFound(URLRequest)
    case noURL
    case requestValidationFailed(URLRequest)
}

extension MockURLSessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unableToLocateResponse(let path):
            return "Failed to find mock response at: \(path) or the default folder"

        case .unableToParseResponse(let data):
            return "Failed to parse mock response: \(String(data: data, encoding: .utf8) ?? "")"

        case .mockRequestNotFound(let request):
            return "Mock request not found for \(request.httpMethod ?? "") request \(request.url?.path ?? "")"

        case .noURL:
            return "Incoming mock request has no URL"

        case .requestValidationFailed(let request):
            return "Request validation failed for \(request.httpMethod ?? "") request \(request.url?.path ?? "")"
        }
    }
}
