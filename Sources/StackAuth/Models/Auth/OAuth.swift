import Foundation

// MARK: - OAuthProvider

public class OAuthProvider: Codable {
    public let id: String
    public let type: String
    public let userId: String
    public var accountId: String?
    public var email: String?
    public var allowSignIn: Bool
    public var allowConnectedAccounts: Bool

    weak var app: StackClientApp?

    enum CodingKeys: String, CodingKey {
        case id, type, userId, accountId, email, allowSignIn, allowConnectedAccounts
    }

    public init(
        id: String,
        type: String,
        userId: String,
        accountId: String? = nil,
        email: String? = nil,
        allowSignIn: Bool,
        allowConnectedAccounts: Bool
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.accountId = accountId
        self.email = email
        self.allowSignIn = allowSignIn
        self.allowConnectedAccounts = allowConnectedAccounts
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        userId = try container.decode(String.self, forKey: .userId)
        accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        allowSignIn = try container.decodeIfPresent(Bool.self, forKey: .allowSignIn) ?? false
        allowConnectedAccounts = try container.decodeIfPresent(Bool.self, forKey: .allowConnectedAccounts) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(allowSignIn, forKey: .allowSignIn)
        try container.encode(allowConnectedAccounts, forKey: .allowConnectedAccounts)
    }

    public struct UpdateOptions {
        public var allowSignIn: Bool?
        public var allowConnectedAccounts: Bool?

        public init(allowSignIn: Bool? = nil, allowConnectedAccounts: Bool? = nil) {
            self.allowSignIn = allowSignIn
            self.allowConnectedAccounts = allowConnectedAccounts
        }
    }

    public func update(_ options: UpdateOptions) async -> Result<Void, StackAuthAPIError> {
        guard let app = app else {
            return .failure(StackAuthAPIError(code: "no_app", message: "No app reference"))
        }

        var body: [String: Any] = [:]
        if let allowSignIn = options.allowSignIn {
            body["allowSignIn"] = allowSignIn
        }
        if let allowConnectedAccounts = options.allowConnectedAccounts {
            body["allowConnectedAccounts"] = allowConnectedAccounts
        }

        do {
            let accessToken = await app.tokenStore.getAccessToken()
            try await app.apiClient.requestVoid(
                path: "/users/me/oauth-providers/\(id)",
                method: "PATCH",
                body: body,
                accessToken: accessToken
            )

            // Update local properties
            if let allowSignIn = options.allowSignIn {
                self.allowSignIn = allowSignIn
            }
            if let allowConnectedAccounts = options.allowConnectedAccounts {
                self.allowConnectedAccounts = allowConnectedAccounts
            }

            return .success(())
        } catch let error as StackAuthAPIError {
            return .failure(error)
        } catch {
            return .failure(StackAuthAPIError(code: "unknown", message: error.localizedDescription))
        }
    }

    public func delete() async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/users/me/oauth-providers/\(id)",
            method: "DELETE",
            accessToken: accessToken
        )
    }
}

// MARK: - ServerOAuthProvider

public class ServerOAuthProvider: OAuthProvider {
    public override var accountId: String? {
        get { super.accountId }
        set { super.accountId = newValue }
    }

    public init(from provider: OAuthProvider) {
        super.init(
            id: provider.id,
            type: provider.type,
            userId: provider.userId,
            accountId: provider.accountId,
            email: provider.email,
            allowSignIn: provider.allowSignIn,
            allowConnectedAccounts: provider.allowConnectedAccounts
        )
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    public struct ServerUpdateOptions {
        public var accountId: String?
        public var email: String?
        public var allowSignIn: Bool?
        public var allowConnectedAccounts: Bool?

        public init(
            accountId: String? = nil,
            email: String? = nil,
            allowSignIn: Bool? = nil,
            allowConnectedAccounts: Bool? = nil
        ) {
            self.accountId = accountId
            self.email = email
            self.allowSignIn = allowSignIn
            self.allowConnectedAccounts = allowConnectedAccounts
        }
    }

    public func updateServer(_ options: ServerUpdateOptions) async -> Result<Void, StackAuthAPIError> {
        guard let app = app as? StackServerApp else {
            return .failure(StackAuthAPIError(code: "no_app", message: "No server app reference"))
        }

        var body: [String: Any] = [:]
        if let accountId = options.accountId {
            body["accountId"] = accountId
        }
        if let email = options.email {
            body["email"] = email
        }
        if let allowSignIn = options.allowSignIn {
            body["allowSignIn"] = allowSignIn
        }
        if let allowConnectedAccounts = options.allowConnectedAccounts {
            body["allowConnectedAccounts"] = allowConnectedAccounts
        }

        do {
            try await app.apiClient.requestVoid(
                path: "/users/\(userId)/oauth-providers/\(id)",
                method: "PATCH",
                body: body,
                isServerOnly: true
            )

            // Update local properties
            if let accountId = options.accountId {
                self.accountId = accountId
            }
            if let email = options.email {
                self.email = email
            }
            if let allowSignIn = options.allowSignIn {
                self.allowSignIn = allowSignIn
            }
            if let allowConnectedAccounts = options.allowConnectedAccounts {
                self.allowConnectedAccounts = allowConnectedAccounts
            }

            return .success(())
        } catch let error as StackAuthAPIError {
            return .failure(error)
        } catch {
            return .failure(StackAuthAPIError(code: "unknown", message: error.localizedDescription))
        }
    }

    public func deleteServer() async throws {
        guard let app = app as? StackServerApp else { return }
        try await app.apiClient.requestVoid(
            path: "/users/\(userId)/oauth-providers/\(id)",
            method: "DELETE",
            isServerOnly: true
        )
    }
}

// MARK: - LiveOAuthConnection

/// A live OAuth connection client that can retrieve access tokens
public class LiveOAuthConnection {
    public let id: String
    private let accessTokenProvider: () async throws -> String

    weak var app: StackClientApp?

    public init(id: String, app: StackClientApp?, accessTokenProvider: @escaping () async throws -> String) {
        self.id = id
        self.app = app
        self.accessTokenProvider = accessTokenProvider
    }

    public func getAccessToken() async throws -> String {
        return try await accessTokenProvider()
    }
}
