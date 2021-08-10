import Foundation

/// `URLSessionType` implementation used for recording the mock jsons in the local file system
public class RecordURLSession: URLSessionType {
    let urlSession: URLSessionType
    let recordPath = "-recorded"
    var urlCounter: [String: Int] = [:]

    /// creates an instance of `RecordURLSession` that uses the provided `URLSessionType` for communication
    ///
    /// - Parameter urlSession: an instance conforming to `URLSessionType` defaults to `URLSession.shared`
    public init(urlSession: URLSessionType = URLSession.shared) {
        self.urlSession = urlSession
    }

    public func send(_ request: URLRequest, completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) {
        urlSession.send(request) { result in
            switch result {
            case .success(let response):
                if
                    let responsePath = ProcessInfo.processInfo.environment["mock_responses"],
                    let directory = URL(string: responsePath),
                    let filename = request.url?.path.fileName,
                    let docURL = URL(string: responsePath)
                {
                    let data = response.0
                    let httpResponse = response.1
                    self.urlCounter[filename, default: -1] += 1
                    var timesRecorded = 0

                    if let urlCount = self.urlCounter[filename] {
                        timesRecorded = urlCount
                    }

                    let pathWithFileName = directory
                        .appendingPathComponent(self.recordPath)
                        .appendingPathComponent(filename.appending("/\(timesRecorded).json"))

                    do {
                        let body = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        let dictionary: [String: Any] = [
                            "status": httpResponse.statusCode,
                            "response": body ?? [:]
                        ]
                        // create record path folder and api path folders
                        try self.createFolder(url: docURL.appendingPathComponent(self.recordPath))
                        try self.createFolder(
                            url: docURL.appendingPathComponent(self.recordPath).appendingPathComponent(filename)
                        )

                        try JSONSerialization
                            .data(withJSONObject: dictionary, options: .prettyPrinted)
                            .write(to: pathWithFileName)

                        print("RECORDED TO PATH: ", pathWithFileName, "\n\n\n")
                    } catch {
                        print("ERROR RECORDING: ", error, "\n\n\n")
                    }
                    completionHandler(.success((data, httpResponse)))
                }

            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    private func createFolder(url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(
                atPath: url.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

private extension String {
    var fileName: String {
        replacingOccurrences(of: "/", with: ":")
    }
}
