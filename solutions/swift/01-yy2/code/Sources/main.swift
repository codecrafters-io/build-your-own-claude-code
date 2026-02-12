import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let args = CommandLine.arguments
guard let pIndex = args.firstIndex(of: "-p"), pIndex + 1 < args.count else {
    FileHandle.standardError.write(Data("error: -p flag is required\n".utf8))
    exit(1)
}
let prompt = args[pIndex + 1]

guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty else {
    FileHandle.standardError.write(Data("OPENROUTER_API_KEY is not set\n".utf8))
    exit(1)
}
let baseURL = ProcessInfo.processInfo.environment["OPENROUTER_BASE_URL"] ?? "https://openrouter.ai/api/v1"

var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
request.httpMethod = "POST"
request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: [
    "model": "anthropic/claude-haiku-4.5",
    "messages": [["role": "user", "content": prompt]]
] as [String: Any])

let semaphore = DispatchSemaphore(value: 0)
nonisolated(unsafe) var responseData: Data?
nonisolated(unsafe) var responseError: (any Error)?

URLSession.shared.dataTask(with: request) { data, _, error in
    responseData = data
    responseError = error
    semaphore.signal()
}.resume()
semaphore.wait()

if let error = responseError {
    FileHandle.standardError.write(Data("Request failed: \(error)\n".utf8))
    exit(1)
}

guard let data = responseData,
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let choices = json["choices"] as? [[String: Any]],
      !choices.isEmpty,
      let message = choices[0]["message"] as? [String: Any],
      let content = message["content"] as? String else {
    FileHandle.standardError.write(Data("no choices in response\n".utf8))
    exit(1)
}

print(content, terminator: "")
