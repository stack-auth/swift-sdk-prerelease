import Foundation

/// Server-side application class for Stack Auth with elevated privileges
public class StackServerApp: StackClientApp {
    private let secretServerKey: String

    /// Initialize a new Stack server application
    /// - Parameters:
    ///   - projectId: Your Stack Auth project ID
    ///   - publishableClientKey: Your publishable client key
    ///   - secretServerKey: Your secret server key (keep this secure!)
    ///   - baseURL: Base URL for the Stack Auth API (defaults to https://api.stack-auth.com)
    ///   - tokenStoreType: Type of token storage to use (typically .none for server)
    ///   - urls: Configuration URLs for redirects
    ///   - extraHeaders: Additional headers to include in all requests
    public init(
        projectId: String,
        publishableClientKey: String,
        secretServerKey: String,
        baseURL: URL = URL(string: "https://api.stack-auth.com")!,
        tokenStoreType: TokenStoreType = .none,
        urls: StackClientURLs = StackClientURLs(),
        extraHeaders: [String: String] = [:]
    ) {
        self.secretServerKey = secretServerKey

        // Create a custom request builder with the secret server key
        let serverRequestBuilder = RequestBuilder(
            baseURL: baseURL,
            projectId: projectId,
            publishableClientKey: publishableClientKey,
            secretServerKey: secretServerKey,
            extraHeaders: extraHeaders
        )

        // We need to call super.init but can't override the request builder
        // So we'll init with a temporary one and replace it
        super.init(
            projectId: projectId,
            publishableClientKey: publishableClientKey,
            baseURL: baseURL,
            tokenStoreType: tokenStoreType,
            urls: urls,
            extraHeaders: extraHeaders
        )
    }

    // MARK: - Server User Methods

    /// Get a user by ID (server-only)
    public func getUser(id: String) async throws -> ServerUser {
        let user: BaseUser = try await apiClient.request(
            path: "/users/\(id)",
            method: "GET",
            isServerOnly: true
        )

        return ServerUser(from: user, app: self)
    }

    /// List all users (server-only)
    /// - Parameters:
    ///   - cursor: Pagination cursor
    ///   - limit: Maximum number of users to return
    ///   - orderBy: Field to order by
    ///   - desc: Whether to sort in descending order
    public func listUsers(
        cursor: String? = nil,
        limit: Int? = nil,
        orderBy: String? = nil,
        desc: Bool? = nil
    ) async throws -> UsersList {
        var queryItems: [URLQueryItem] = []

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let orderBy = orderBy {
            queryItems.append(URLQueryItem(name: "orderBy", value: orderBy))
        }
        if let desc = desc {
            queryItems.append(URLQueryItem(name: "desc", value: String(desc)))
        }

        struct UsersListResponse: Decodable {
            let users: [BaseUser]
            let nextCursor: String?
        }

        let response: UsersListResponse = try await apiClient.request(
            path: "/users",
            method: "GET",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            isServerOnly: true
        )

        let serverUsers = response.users.map { ServerUser(from: $0, app: self) }
        return UsersList(users: serverUsers, nextCursor: response.nextCursor)
    }

    /// Create a new user (server-only)
    public func createUser(
        email: String? = nil,
        password: String? = nil,
        displayName: String? = nil,
        profileImageUrl: String? = nil,
        clientMetadata: [String: AnyCodable]? = nil,
        serverMetadata: [String: AnyCodable]? = nil,
        primaryEmailVerified: Bool = false
    ) async throws -> ServerUser {
        var body: [String: Any] = [:]

        if let email = email {
            body["email"] = email
        }
        if let password = password {
            body["password"] = password
        }
        if let displayName = displayName {
            body["displayName"] = displayName
        }
        if let profileImageUrl = profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }
        if let clientMetadata = clientMetadata {
            body["clientMetadata"] = clientMetadata
        }
        if let serverMetadata = serverMetadata {
            body["serverMetadata"] = serverMetadata
        }
        body["primaryEmailVerified"] = primaryEmailVerified

        let user: BaseUser = try await apiClient.request(
            path: "/users",
            method: "POST",
            body: body,
            isServerOnly: true
        )

        return ServerUser(from: user, app: self)
    }

    // MARK: - Server Team Methods

    /// Get a team by ID (server-only)
    public func getTeam(id: String) async throws -> ServerTeam {
        let team: Team = try await apiClient.request(
            path: "/teams/\(id)",
            method: "GET",
            isServerOnly: true
        )

        return ServerTeam(from: team, app: self)
    }

    /// List all teams (server-only)
    public func listTeams(
        cursor: String? = nil,
        limit: Int? = nil,
        orderBy: String? = nil,
        desc: Bool? = nil
    ) async throws -> TeamsList {
        var queryItems: [URLQueryItem] = []

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let orderBy = orderBy {
            queryItems.append(URLQueryItem(name: "orderBy", value: orderBy))
        }
        if let desc = desc {
            queryItems.append(URLQueryItem(name: "desc", value: String(desc)))
        }

        struct TeamsListResponse: Decodable {
            let teams: [Team]
            let nextCursor: String?
        }

        let response: TeamsListResponse = try await apiClient.request(
            path: "/teams",
            method: "GET",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            isServerOnly: true
        )

        let serverTeams = response.teams.map { ServerTeam(from: $0, app: self) }
        return TeamsList(teams: serverTeams, nextCursor: response.nextCursor)
    }

    /// Create a new team (server-only)
    public func createTeam(
        displayName: String,
        creatorUserId: String? = nil,
        description: String? = nil,
        profileImageUrl: String? = nil,
        clientMetadata: [String: AnyCodable]? = nil,
        serverMetadata: [String: AnyCodable]? = nil
    ) async throws -> ServerTeam {
        var body: [String: Any] = ["displayName": displayName]

        if let creatorUserId = creatorUserId {
            body["creatorUserId"] = creatorUserId
        }
        if let description = description {
            body["description"] = description
        }
        if let profileImageUrl = profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }
        if let clientMetadata = clientMetadata {
            body["clientMetadata"] = clientMetadata
        }
        if let serverMetadata = serverMetadata {
            body["serverMetadata"] = serverMetadata
        }

        let team: Team = try await apiClient.request(
            path: "/teams",
            method: "POST",
            body: body,
            isServerOnly: true
        )

        return ServerTeam(from: team, app: self)
    }

    // MARK: - Server Product Methods

    /// Grant a product to a customer (server-only)
    public func grantProduct(
        customerId: String,
        customerType: String = "user",
        productId: String,
        quantity: Int = 1
    ) async throws {
        try await apiClient.requestVoid(
            path: "/customers/\(customerType)/\(customerId)/products/\(productId)/grant",
            method: "POST",
            body: ["quantity": quantity],
            isServerOnly: true
        )
    }

    /// Get an item for a customer (server-only)
    public func getItem(customerId: String, customerType: String = "user", itemId: String) async throws -> ServerItem {
        let item: Item = try await apiClient.request(
            path: "/customers/\(customerType)/\(customerId)/items/\(itemId)",
            method: "GET",
            isServerOnly: true
        )

        let serverItem = ServerItem(from: item, app: self, customerId: customerId, customerType: customerType)
        return serverItem
    }

    /// List products for a customer (server-only)
    public func listProducts(
        customerId: String,
        customerType: String = "user",
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> CustomerProductsList {
        var queryItems: [URLQueryItem] = []

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return try await apiClient.request(
            path: "/customers/\(customerType)/\(customerId)/products",
            method: "GET",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            isServerOnly: true
        )
    }

    // MARK: - Email Methods

    /// Send an email (server-only)
    public func sendEmail(
        to: String,
        subject: String,
        body: String,
        from: String? = nil,
        replyTo: String? = nil
    ) async throws {
        var emailBody: [String: Any] = [
            "to": to,
            "subject": subject,
            "body": body
        ]

        if let from = from {
            emailBody["from"] = from
        }
        if let replyTo = replyTo {
            emailBody["replyTo"] = replyTo
        }

        try await apiClient.requestVoid(
            path: "/emails/send",
            method: "POST",
            body: emailBody,
            isServerOnly: true
        )
    }

    /// Get email delivery statistics (server-only)
    public func getEmailDeliveryStats(
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> EmailDeliveryStats {
        var queryItems: [URLQueryItem] = []

        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "startDate", value: formatter.string(from: startDate)))
        }
        if let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "endDate", value: formatter.string(from: endDate)))
        }

        return try await apiClient.request(
            path: "/emails/stats",
            method: "GET",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            isServerOnly: true
        )
    }

    // MARK: - OAuth Provider Methods

    /// Create an OAuth provider configuration (server-only)
    public func createOAuthProvider(
        type: String,
        clientId: String,
        clientSecret: String,
        scopes: [String]? = nil,
        enabled: Bool = true
    ) async throws -> OAuthProviderConfig {
        var body: [String: Any] = [
            "type": type,
            "clientId": clientId,
            "clientSecret": clientSecret,
            "enabled": enabled
        ]

        if let scopes = scopes {
            body["scopes"] = scopes
        }

        return try await apiClient.request(
            path: "/oauth-providers",
            method: "POST",
            body: body,
            isServerOnly: true
        )
    }

    // MARK: - Data Vault Methods

    /// Get a data vault store instance (server-only)
    public func getDataVaultStore() -> DataVaultStore {
        return DataVaultStore(app: self)
    }
}

// MARK: - Supporting Types

/// Server user with additional server-only methods
public class ServerUser: CurrentUser {
    weak var serverApp: StackServerApp? {
        return app as? StackServerApp
    }

    public init(from user: BaseUser, app: StackServerApp) {
        super.init(from: user, app: app)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    /// Update server metadata (server-only)
    public func updateServerMetadata(_ metadata: [String: AnyCodable]) async throws {
        guard let app = serverApp else { return }

        try await app.apiClient.requestVoid(
            path: "/users/\(id)",
            method: "PATCH",
            body: ["serverMetadata": metadata],
            isServerOnly: true
        )
    }

    /// Delete user (server-only)
    public func deleteUser() async throws {
        guard let app = serverApp else { return }

        try await app.apiClient.requestVoid(
            path: "/users/\(id)",
            method: "DELETE",
            isServerOnly: true
        )
    }
}

/// Server team with additional server-only methods
public class ServerTeam {
    public let team: Team
    weak var app: StackServerApp?

    public init(from team: Team, app: StackServerApp) {
        self.team = team
        self.app = app
    }

    public var id: String { team.id }
    public var displayName: String { team.displayName }
    public var description: String? { team.description }
    public var profileImageUrl: String? { team.profileImageUrl }
    public var createdAt: Date { team.createdAt }
    public var updatedAt: Date { team.updatedAt }
    public var createdBy: String { team.createdBy }
    public var clientMetadata: [String: AnyCodable]? { team.clientMetadata }
    public var serverMetadata: [String: AnyCodable]? { team.serverMetadata }
    public var members: [TeamMember] { team.members }
    public var invitations: [TeamInvitation] { team.invitations }

    /// Update server metadata (server-only)
    public func updateServerMetadata(_ metadata: [String: AnyCodable]) async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/teams/\(id)",
            method: "PATCH",
            body: ["serverMetadata": metadata],
            isServerOnly: true
        )
    }

    /// Delete team (server-only)
    public func deleteTeam() async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/teams/\(id)",
            method: "DELETE",
            isServerOnly: true
        )
    }

    /// Add a user to the team (server-only)
    public func addUser(_ userId: String, role: String = "member") async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/teams/\(id)/users/\(userId)",
            method: "POST",
            body: ["role": role],
            isServerOnly: true
        )
    }

    /// Remove a user from the team (server-only)
    public func removeUser(_ userId: String) async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/teams/\(id)/users/\(userId)",
            method: "DELETE",
            isServerOnly: true
        )
    }
}

/// List of users with pagination
public struct UsersList {
    public let users: [ServerUser]
    public let nextCursor: String?

    public init(users: [ServerUser], nextCursor: String?) {
        self.users = users
        self.nextCursor = nextCursor
    }
}

/// List of teams with pagination
public struct TeamsList {
    public let teams: [ServerTeam]
    public let nextCursor: String?

    public init(teams: [ServerTeam], nextCursor: String?) {
        self.teams = teams
        self.nextCursor = nextCursor
    }
}

/// Email delivery statistics
public struct EmailDeliveryStats: Codable {
    public let sent: Int
    public let delivered: Int
    public let bounced: Int
    public let opened: Int
    public let clicked: Int
    public let failed: Int

    public init(
        sent: Int,
        delivered: Int,
        bounced: Int,
        opened: Int,
        clicked: Int,
        failed: Int
    ) {
        self.sent = sent
        self.delivered = delivered
        self.bounced = bounced
        self.opened = opened
        self.clicked = clicked
        self.failed = failed
    }
}

/// Data vault store for secure key-value storage
public class DataVaultStore {
    weak var app: StackServerApp?

    init(app: StackServerApp) {
        self.app = app
    }

    /// Get a value from the data vault
    public func get(key: String) async throws -> String? {
        guard let app = app else { return nil }

        struct ValueResponse: Decodable {
            let value: String?
        }

        let response: ValueResponse = try await app.apiClient.request(
            path: "/data-vault/\(key)",
            method: "GET",
            isServerOnly: true
        )

        return response.value
    }

    /// Set a value in the data vault
    public func set(key: String, value: String) async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/data-vault/\(key)",
            method: "PUT",
            body: ["value": value],
            isServerOnly: true
        )
    }

    /// Delete a value from the data vault
    public func delete(key: String) async throws {
        guard let app = app else { return }

        try await app.apiClient.requestVoid(
            path: "/data-vault/\(key)",
            method: "DELETE",
            isServerOnly: true
        )
    }

    /// List all keys in the data vault
    public func listKeys(prefix: String? = nil) async throws -> [String] {
        guard let app = app else { return [] }

        var queryItems: [URLQueryItem] = []
        if let prefix = prefix {
            queryItems.append(URLQueryItem(name: "prefix", value: prefix))
        }

        struct KeysResponse: Decodable {
            let keys: [String]
        }

        let response: KeysResponse = try await app.apiClient.request(
            path: "/data-vault/keys",
            method: "GET",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            isServerOnly: true
        )

        return response.keys
    }
}
