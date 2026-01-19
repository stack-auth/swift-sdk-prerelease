import Foundation

public struct RequestBuilder {
    private let baseURL: URL
    private let projectId: String
    private let publishableClientKey: String
    private let secretServerKey: String?
    private let extraHeaders: [String: String]
    private let sdkVersion: String = "1.0.0"
    private let apiVersion: String = "v1"

    public init(
        baseURL: URL,
        projectId: String,
        publishableClientKey: String,
        secretServerKey: String? = nil,
        extraHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.projectId = projectId
        self.publishableClientKey = publishableClientKey
        self.secretServerKey = secretServerKey
        self.extraHeaders = extraHeaders
    }

    public func buildRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        isServerOnly: Bool = false
    ) throws -> URLRequest {
        // Add /api/v1 prefix to all paths
        let versionedPath = "/api/\(apiVersion)\(path)"
        var components = URLComponents(url: baseURL.appendingPathComponent(versionedPath), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Base headers
        request.setValue(projectId, forHTTPHeaderField: "x-stack-project-id")
        request.setValue(publishableClientKey, forHTTPHeaderField: "x-stack-publishable-client-key")
        request.setValue("swift@\(sdkVersion)", forHTTPHeaderField: "x-stack-client-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Access type header - required by the API
        request.setValue(isServerOnly ? "server" : "client", forHTTPHeaderField: "x-stack-access-type")

        // Auth headers
        if let accessToken = accessToken {
            request.setValue(accessToken, forHTTPHeaderField: "x-stack-access-token")
        }

        if let refreshToken = refreshToken {
            request.setValue(refreshToken, forHTTPHeaderField: "x-stack-refresh-token")
        }

        // Server-only header
        if isServerOnly, let secretServerKey = secretServerKey {
            request.setValue(secretServerKey, forHTTPHeaderField: "x-stack-secret-server-key")
        }

        // Extra headers
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Body
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    public func convertKeysToSnakeCase(_ dict: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in dict {
            let snakeKey = key.camelCaseToSnakeCase()
            if let dictValue = value as? [String: Any] {
                result[snakeKey] = convertKeysToSnakeCase(dictValue)
            } else if let arrayValue = value as? [[String: Any]] {
                result[snakeKey] = arrayValue.map { convertKeysToSnakeCase($0) }
            } else {
                result[snakeKey] = value
            }
        }
        return result
    }
}

extension String {
    func camelCaseToSnakeCase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }

    func snakeCaseToCamelCase() -> String {
        let components = self.split(separator: "_")
        if components.isEmpty {
            return self
        }
        let first = String(components[0])
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }
}

extension Dictionary where Key == String {
    func convertKeysToCamelCase() -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in self {
            let camelKey = key.snakeCaseToCamelCase()
            if let dictValue = value as? [String: Any] {
                result[camelKey] = dictValue.convertKeysToCamelCase()
            } else if let arrayValue = value as? [[String: Any]] {
                result[camelKey] = arrayValue.map { $0.convertKeysToCamelCase() }
            } else {
                result[camelKey] = value
            }
        }
        return result
    }
}
