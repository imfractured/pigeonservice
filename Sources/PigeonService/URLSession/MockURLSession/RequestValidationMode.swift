public enum RequestValidationMode: Equatable {
    case none
    case match(Set<Criteria>)

    public enum Criteria: Hashable {
        case matchBody
        case matchBodyIgnoring(keys: [String])
        case matchHeaders
        case matchHeadersIgnoring(keys: [String])
    }
}

public extension Set where Element == RequestValidationMode.Criteria {
    static var all: Self { [.matchBody, .matchHeaders] }

    var matchBody: Bool {
        contains(
            where: {
                switch $0 {
                case.matchBody, .matchBodyIgnoring:
                    return true

                default:
                    return false
                }
            }
        )
    }

    var matchHeaders: Bool {
        contains(
            where: {
                switch $0 {
                case .matchHeaders, .matchHeadersIgnoring:
                    return true

                default:
                    return false
                }
            }
        )
    }
}
