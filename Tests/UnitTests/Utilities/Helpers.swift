import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import PigeonService

struct TestError: LocalizedError, Equatable {
    var message: String = "Test Error"

    var errorDescription: String? {
        message
    }
}

// This is being used to cause a JSON encoding failure by using infinity [Muhammad U. Ali]
// More info here: https://developer.apple.com/documentation/foundation/jsonencoder/2895034-encode
let unencodableFloat = Float.infinity
