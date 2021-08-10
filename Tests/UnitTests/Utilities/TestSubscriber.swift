import Combine
import XCTest

// TODO: Move these helpers into a separate SPM [Muhammad U. Ali]
// that can be shared between app and this SPM
enum CombineEvent<Value, Failure: Error> {
    case success(Value)
    case failure(Failure)
    case finished

    var value: Value? {
        switch self {
        case .success(let value):
            return value

        case .failure:
            return nil

        case .finished:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .success:
            return nil

        case .failure(let error):
            return error

        case .finished:
            return nil
        }
    }

    var isFinished: Bool {
        switch self {
        case .success:
            return false

        case .failure:
            return false

        case .finished:
            return true
        }
    }

    var isError: Bool { error != nil }
}

extension Subscribers {
    class Test<Input, Failure: Error>: Subscriber {
        private(set) var events: [CombineEvent<Input, Failure>] = []

        func receive(_ input: Input) -> Subscribers.Demand {
            events.append(.success(input))
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            switch completion {
            case .failure(let error):
                events.append(.failure(error))

            case .finished:
                events.append(.finished)
            }
        }

        func receive(subscription: Subscription) {
            subscription.request(.unlimited)
        }
    }
}

class TestSubscriberTests: XCTestCase {
    var sut: Subscribers.Test<Int, Error>!
    var passthrough: PassthroughSubject<Int, Error>!

    override func setUp() {
        sut = Subscribers.Test()
        passthrough = PassthroughSubject()
        passthrough.subscribe(sut)
    }

    func test_Success() {
        passthrough.send(99)

        XCTAssertEqual(sut.events.count, 1)

        let event = sut.events[0]
        XCTAssertEqual(event.value, 99)
        XCTAssertNil(event.error)
        XCTAssertFalse(event.isFinished)
        XCTAssertFalse(event.isError)
    }

    func test_Failure() {
        passthrough.send(completion: .failure(TestError()))

        XCTAssertEqual(sut.events.count, 1)

        let event = sut.events[0]
        XCTAssertNil(event.value)
        XCTAssertTrue(event.error is TestError)
        XCTAssertFalse(event.isFinished)
        XCTAssertTrue(event.isError)
    }

    func test_Finished() {
        passthrough.send(completion: .finished)

        XCTAssertEqual(sut.events.count, 1)

        let event = sut.events[0]
        XCTAssertNil(event.value)
        XCTAssertNil(event.error)
        XCTAssertTrue(event.isFinished)
        XCTAssertFalse(event.isError)
    }

    func test_CombineRemovesSubscriptionAfterFailure() {
        passthrough.send(completion: .failure(TestError()))
        passthrough.send(404)

        XCTAssertEqual(sut.events.count, 1)
        XCTAssertTrue(sut.events[0].error is TestError)
    }

    func test_CombineRemovesSubscriptionAfterFinished() {
        passthrough.send(completion: .finished)
        passthrough.send(404)

        XCTAssertEqual(sut.events.count, 1)
        XCTAssertTrue(sut.events[0].isFinished)
    }

    func test_multipleEvents() {
        passthrough.send(99)
        passthrough.send(88)
        passthrough.send(completion: .finished)

        XCTAssertEqual(sut.events.count, 3)
        XCTAssertEqual(sut.events[0].value, 99)
        XCTAssertEqual(sut.events[1].value, 88)
        XCTAssertTrue(sut.events[2].isFinished)
    }
}
