import Foundation

public actor APIClient {
    private let requestBuilder: RequestBuilder
    private let session: URLSession

    public init(requestBuilder: RequestBuilder, session: URLSession = .shared) {
        self.requestBuilder = requestBuilder
        self.session = session
    }

    public func request<T: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        isServerOnly: Bool = false
    ) async throws -> T {
        let convertedBody = body.map { requestBuilder.convertKeysToSnakeCase($0) }
        let request = try requestBuilder.buildRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: convertedBody,
            accessToken: accessToken,
            refreshToken: refreshToken,
            isServerOnly: isServerOnly
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode >= 400 {
            // Try to parse error from body - handle both {"error": {...}} and {...} formats
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check for nested error object: {"error": {"code": "...", "message": "..."}}
                let errorDict: [String: Any]
                if let nestedError = json["error"] as? [String: Any] {
                    errorDict = nestedError
                } else {
                    errorDict = json
                }
                
                // Get code from header or body
                let headerCode = httpResponse.value(forHTTPHeaderField: "x-stack-known-error")
                let code = errorDict["code"] as? String ?? headerCode ?? "\(httpResponse.statusCode)"
                let message = errorDict["message"] as? String ?? "HTTP \(httpResponse.statusCode) error"
                let details = (errorDict["details"] as? [String: Any])?.mapValues { AnyCodable($0) }
                throw StackAuthAPIError(code: code, message: message, details: details)
            }

            // Fallback for non-JSON errors
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw StackAuthAPIError(code: "\(httpResponse.statusCode)", message: message, details: nil)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }

    public func requestVoid(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        isServerOnly: Bool = false
    ) async throws {
        struct EmptyResponse: Decodable {}
        let _: EmptyResponse? = try? await request(
            path: path,
            method: method,
            queryItems: queryItems,
            body: body,
            accessToken: accessToken,
            refreshToken: refreshToken,
            isServerOnly: isServerOnly
        )
    }

    public func requestWithResult<T: Decodable, E: Error>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        isServerOnly: Bool = false,
        errorCodes: [String: () -> E]
    ) async -> Result<T, E> {
        do {
            let result: T = try await request(
                path: path,
                method: method,
                queryItems: queryItems,
                body: body,
                accessToken: accessToken,
                refreshToken: refreshToken,
                isServerOnly: isServerOnly
            )
            return .success(result)
        } catch let error as StackAuthAPIError {
            if let errorFactory = errorCodes[error.code] {
                return .failure(errorFactory())
            }
            // Unexpected error code
            return .failure(error as! E)
        } catch {
            return .failure(error as! E)
        }
    }
}
