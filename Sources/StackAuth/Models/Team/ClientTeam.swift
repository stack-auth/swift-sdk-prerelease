import Foundation

/// The team with methods to interact with team data (client-side)
public class ClientTeam: Team {
    public init(from team: Team, app: StackClientApp?) {
        super.init(
            id: team.id,
            displayName: team.displayName,
            description: team.description,
            profileImageUrl: team.profileImageUrl,
            createdAt: team.createdAt,
            updatedAt: team.updatedAt,
            createdBy: team.createdBy,
            clientMetadata: team.clientMetadata,
            serverMetadata: team.serverMetadata,
            members: team.members,
            invitations: team.invitations,
            settings: team.settings
        )
        self.app = app
    }

    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update Methods

    public struct UpdateOptions {
        public var displayName: String?
        public var description: String?
        public var profileImageUrl: String?
        public var clientMetadata: [String: AnyCodable]?
        public var settings: TeamSettings?

        public init(
            displayName: String? = nil,
            description: String? = nil,
            profileImageUrl: String? = nil,
            clientMetadata: [String: AnyCodable]? = nil,
            settings: TeamSettings? = nil
        ) {
            self.displayName = displayName
            self.description = description
            self.profileImageUrl = profileImageUrl
            self.clientMetadata = clientMetadata
            self.settings = settings
        }
    }

    public func update(_ options: UpdateOptions) async throws {
        guard let app = app else { return }

        var body: [String: Any] = [:]
        if let displayName = options.displayName {
            body["displayName"] = displayName
        }
        if let description = options.description {
            body["description"] = description
        }
        if let profileImageUrl = options.profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }
        if let clientMetadata = options.clientMetadata {
            body["clientMetadata"] = clientMetadata
        }
        if let settings = options.settings {
            body["settings"] = [
                "membersCanInvite": settings.membersCanInvite,
                "isPublic": settings.isPublic,
                "defaultMemberRole": settings.defaultMemberRole,
                "maxMembers": settings.maxMembers as Any,
                "requireEmailVerification": settings.requireEmailVerification,
                "customDomain": settings.customDomain as Any
            ]
        }

        let accessToken = await app.tokenStore.getAccessToken()
        let updatedTeam: Team = try await app.apiClient.request(
            path: "/teams/\(id)",
            method: "PATCH",
            body: body,
            accessToken: accessToken
        )

        // Update local properties
        if let displayName = options.displayName {
            self.displayName = displayName
        }
        if let description = options.description {
            self.description = description
        }
        if let profileImageUrl = options.profileImageUrl {
            self.profileImageUrl = profileImageUrl
        }
        if let clientMetadata = options.clientMetadata {
            self.clientMetadata = clientMetadata
        }
        if let settings = options.settings {
            self.settings = settings
        }
    }

    public func delete() async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/teams/\(id)",
            method: "DELETE",
            accessToken: accessToken
        )
    }

    // MARK: - User Management

    public func inviteUser(_ request: InviteTeamMemberRequest) async throws -> TeamInvitation {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()

        var body: [String: Any] = [
            "email": request.email,
            "role": request.role
        ]
        if let message = request.message {
            body["message"] = message
        }
        if let expiresAt = request.expiresAt {
            body["expiresAt"] = expiresAt
        }

        return try await app.apiClient.request(
            path: "/teams/\(id)/invitations",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
    }

    public func listUsers() async throws -> [TeamUser] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()

        struct UsersResponse: Decodable {
            let users: [TeamUser]
        }

        let response: UsersResponse = try await app.apiClient.request(
            path: "/teams/\(id)/users",
            method: "GET",
            accessToken: accessToken
        )

        return response.users.map { user in
            var mutableUser = user
            mutableUser.app = app
            mutableUser.teamId = id
            return mutableUser
        }
    }

    public func listInvitations() async throws -> [TeamInvitation] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()

        struct InvitationsResponse: Decodable {
            let invitations: [TeamInvitation]
        }

        let response: InvitationsResponse = try await app.apiClient.request(
            path: "/teams/\(id)/invitations",
            method: "GET",
            accessToken: accessToken
        )

        return response.invitations
    }

    // MARK: - API Key Management

    public func createApiKey(_ request: CreateApiKeyRequest) async throws -> ApiKey {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()

        var body: [String: Any] = [:]
        if let description = request.description {
            body["description"] = description
        }
        if let expiresAt = request.expiresAt {
            body["expiresAt"] = expiresAt
        }
        if let permissions = request.permissions {
            body["permissions"] = permissions
        }

        return try await app.apiClient.request(
            path: "/teams/\(id)/api-keys",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
    }

    public func listApiKeys() async throws -> [ApiKey] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()

        struct ApiKeysResponse: Decodable {
            let apiKeys: [ApiKey]
        }

        let response: ApiKeysResponse = try await app.apiClient.request(
            path: "/teams/\(id)/api-keys",
            method: "GET",
            accessToken: accessToken
        )

        return response.apiKeys
    }
}

// MARK: - Customer Protocol Implementation
extension ClientTeam: Customer {
    public func createCheckoutUrl(productId: String, returnUrl: String? = nil) async throws -> String {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var body: [String: Any] = ["productId": productId]
        if let returnUrl = returnUrl {
            body["returnUrl"] = returnUrl
        }

        struct CheckoutResponse: Decodable {
            let url: String
        }

        let response: CheckoutResponse = try await app.apiClient.request(
            path: "/customers/team/\(id)/checkout",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
        return response.url
    }

    public func getBilling() async throws -> CustomerBilling {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        return try await app.apiClient.request(
            path: "/customers/team/\(id)/billing",
            method: "GET",
            accessToken: accessToken
        )
    }

    public func getItem(itemId: String) async throws -> Item {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        return try await app.apiClient.request(
            path: "/customers/team/\(id)/items/\(itemId)",
            method: "GET",
            accessToken: accessToken
        )
    }

    public func listItems() async throws -> [Item] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()

        struct ItemsResponse: Decodable {
            let items: [Item]
        }

        let response: ItemsResponse = try await app.apiClient.request(
            path: "/customers/team/\(id)/items",
            method: "GET",
            accessToken: accessToken
        )

        return response.items
    }

    public func hasItem(itemId: String) async throws -> Bool {
        let item = try await getItem(itemId: itemId)
        return item.quantity > 0
    }

    public func getItemQuantity(itemId: String) async throws -> Int {
        let item = try await getItem(itemId: itemId)
        return item.quantity
    }

    public func listProducts(cursor: String? = nil, limit: Int? = nil) async throws -> CustomerProductsList {
        guard let app = app else {
            return CustomerProductsList(products: [], nextCursor: nil)
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return try await app.apiClient.request(
            path: "/customers/team/\(id)/products",
            method: "GET",
            queryItems: queryItems,
            accessToken: accessToken
        )
    }
}

// MARK: - TeamUser

/// Represents a user within a team context
public struct TeamUser: Codable, Identifiable, Equatable {
    /// User ID
    public let id: String

    /// User's display name
    public let displayName: String?

    /// User's primary email
    public let primaryEmail: String?

    /// User's profile image URL
    public let profileImageUrl: String?

    /// User's role in the team
    public let teamRole: String

    /// When the user joined the team
    public let joinedAt: Date

    /// Whether this user is the team owner
    public let isOwner: Bool

    /// Custom permissions for this user in the team
    public let permissions: [Permission]

    // Internal properties (not decoded from JSON)
    weak var app: StackClientApp?
    var teamId: String = ""

    enum CodingKeys: String, CodingKey {
        case id, displayName, primaryEmail, profileImageUrl, teamRole, joinedAt, isOwner, permissions
    }

    public init(
        id: String,
        displayName: String?,
        primaryEmail: String?,
        profileImageUrl: String?,
        teamRole: String,
        joinedAt: Date,
        isOwner: Bool,
        permissions: [Permission]
    ) {
        self.id = id
        self.displayName = displayName
        self.primaryEmail = primaryEmail
        self.profileImageUrl = profileImageUrl
        self.teamRole = teamRole
        self.joinedAt = joinedAt
        self.isOwner = isOwner
        self.permissions = permissions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        primaryEmail = try container.decodeIfPresent(String.self, forKey: .primaryEmail)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        teamRole = try container.decode(String.self, forKey: .teamRole)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        isOwner = try container.decode(Bool.self, forKey: .isOwner)
        permissions = try container.decode([Permission].self, forKey: .permissions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(primaryEmail, forKey: .primaryEmail)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(teamRole, forKey: .teamRole)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(isOwner, forKey: .isOwner)
        try container.encode(permissions, forKey: .permissions)
    }

    public static func == (lhs: TeamUser, rhs: TeamUser) -> Bool {
        return lhs.id == rhs.id &&
            lhs.displayName == rhs.displayName &&
            lhs.primaryEmail == rhs.primaryEmail &&
            lhs.profileImageUrl == rhs.profileImageUrl &&
            lhs.teamRole == rhs.teamRole &&
            lhs.joinedAt == rhs.joinedAt &&
            lhs.isOwner == rhs.isOwner &&
            lhs.permissions == rhs.permissions
    }

    // MARK: - User Management Methods

    public func updateRole(_ role: String) async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/teams/\(teamId)/users/\(id)",
            method: "PATCH",
            body: ["role": role],
            accessToken: accessToken
        )
    }

    public func remove() async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/teams/\(teamId)/users/\(id)",
            method: "DELETE",
            accessToken: accessToken
        )
    }
}

// MARK: - ApiKey

/// Represents an API key for a team
public struct ApiKey: Codable, Identifiable, Equatable {
    /// Unique identifier for the API key
    public let id: String

    /// The actual API key (only returned on creation)
    public let key: String?

    /// Description of the API key
    public let description: String?

    /// When the API key was created
    public let createdAt: Date

    /// When the API key expires (if applicable)
    public let expiresAt: Date?

    /// When the API key was last used
    public let lastUsedAt: Date?

    /// Permissions associated with this API key
    public let permissions: [String]

    /// Whether this key is currently active
    public let isActive: Bool

    public init(
        id: String,
        key: String?,
        description: String?,
        createdAt: Date,
        expiresAt: Date?,
        lastUsedAt: Date?,
        permissions: [String],
        isActive: Bool
    ) {
        self.id = id
        self.key = key
        self.description = description
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.lastUsedAt = lastUsedAt
        self.permissions = permissions
        self.isActive = isActive
    }

    /// Check if the API key is still valid
    public var isValid: Bool {
        guard isActive else { return false }
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
}

/// Request to create a new API key
public struct CreateApiKeyRequest: Codable, Equatable {
    /// Description for the API key
    public let description: String?

    /// When the API key should expire
    public let expiresAt: Date?

    /// Permissions to grant to this API key
    public let permissions: [String]?

    public init(
        description: String? = nil,
        expiresAt: Date? = nil,
        permissions: [String]? = nil
    ) {
        self.description = description
        self.expiresAt = expiresAt
        self.permissions = permissions
    }
}

// MARK: - TeamPermission

/// Represents a permission in a team context
public struct TeamPermission: Codable, Identifiable, Equatable {
    /// Permission ID
    public let id: String

    /// The permission scope
    public let scope: String

    /// The team this permission applies to
    public let teamId: String?

    /// When this permission was granted
    public let grantedAt: Date

    /// When this permission expires
    public let expiresAt: Date?

    public init(
        id: String,
        scope: String,
        teamId: String?,
        grantedAt: Date,
        expiresAt: Date?
    ) {
        self.id = id
        self.scope = scope
        self.teamId = teamId
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
    }

    /// Check if the permission is still valid
    public var isValid: Bool {
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
}
