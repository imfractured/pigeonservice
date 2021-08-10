import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension HTTPURLResponse {
    /// checks if the response received is a success (`statusCode` is in between 200-299)
    var isSuccess: Bool {
        200..<300 ~= statusCode
    }
}
