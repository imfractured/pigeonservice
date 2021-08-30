import Foundation
public protocol PigeonLogType {
    func log(message: String, level: PigeonLogLevel)
}

public enum PigeonLogLevel {
    case debug
    case info
    case error
}
