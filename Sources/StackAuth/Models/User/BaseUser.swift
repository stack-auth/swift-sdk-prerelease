import Foundation

/// Represents a user in the Stack Auth system
public class BaseUser: Codable, Identifiable {
    /// Unique identifier for the user
    public let id: String

    /// User's primary email address
    public var primaryEmail: String?

    /// Whether the primary email has been verified
    public var primaryEmailVerified: Bool

    /// User's display name
    public var displayName: String?

    /// URL to the user's profile image
    public var profileImageUrl: String?

    /// When the user signed up
    public let signedUpAt: Date

    /// Custom metadata associated with the user (client-readable)
    public var clientMetadata: [String: AnyCodable]?

    /// Custom metadata associated with the user (client read-only)
    public var clientReadOnlyMetadata: [String: AnyCodable]?

    /// Whether the user has a password set
    public var hasPassword: Bool

    /// Whether OTP (One-Time Password) authentication is enabled
    public var otpAuthEnabled: Bool

    /// Whether passkey authentication is enabled
    public var passkeyAuthEnabled: Bool

    /// Whether multi-factor authentication is required
    public let isMultiFactorRequired: Bool

    /// Whether the user is anonymous (guest)
    public let isAnonymous: Bool

    /// Whether the user is restricted
    public let isRestricted: Bool

    /// Reason for restriction, if restricted
    public let restrictedReason: String?

    /// OAuth connections for this user
    public let oauthConnections: [OAuthConnection]

    /// Contact channels (email, phone) for this user
    public let contactChannels: [ContactChannel]

    /// Selected team ID if the user is part of teams
    public let selectedTeamId: String?

    /// All teams the user belongs to
    public let teams: [TeamMembership]

    enum CodingKeys: String, CodingKey {
        case id, primaryEmail, primaryEmailVerified, displayName, profileImageUrl
        case signedUpAt, clientMetadata, clientReadOnlyMetadata, hasPassword
        case otpAuthEnabled, passkeyAuthEnabled, isMultiFactorRequired
        case isAnonymous, isRestricted, restrictedReason
        case oauthConnections, contactChannels, selectedTeamId, teams
    }

    public init(
        id: String,
        displayName: String?,
        primaryEmail: String?,
        primaryEmailVerified: Bool,
        profileImageUrl: String?,
        signedUpAt: Date,
        clientMetadata: [String: AnyCodable]?,
        clientReadOnlyMetadata: [String: AnyCodable]?,
        hasPassword: Bool,
        otpAuthEnabled: Bool,
        passkeyAuthEnabled: Bool,
        isMultiFactorRequired: Bool,
        isAnonymous: Bool,
        isRestricted: Bool,
        restrictedReason: String?,
        oauthConnections: [OAuthConnection] = [],
        contactChannels: [ContactChannel] = [],
        selectedTeamId: String? = nil,
        teams: [TeamMembership] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.primaryEmail = primaryEmail
        self.primaryEmailVerified = primaryEmailVerified
        self.profileImageUrl = profileImageUrl
        self.signedUpAt = signedUpAt
        self.clientMetadata = clientMetadata
        self.clientReadOnlyMetadata = clientReadOnlyMetadata
        self.hasPassword = hasPassword
        self.otpAuthEnabled = otpAuthEnabled
        self.passkeyAuthEnabled = passkeyAuthEnabled
        self.isMultiFactorRequired = isMultiFactorRequired
        self.isAnonymous = isAnonymous
        self.isRestricted = isRestricted
        self.restrictedReason = restrictedReason
        self.oauthConnections = oauthConnections
        self.contactChannels = contactChannels
        self.selectedTeamId = selectedTeamId
        self.teams = teams
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        primaryEmail = try container.decodeIfPresent(String.self, forKey: .primaryEmail)
        primaryEmailVerified = try container.decodeIfPresent(Bool.self, forKey: .primaryEmailVerified) ?? false
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        signedUpAt = try container.decodeIfPresent(Date.self, forKey: .signedUpAt) ?? Date()
        clientMetadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .clientMetadata)
        clientReadOnlyMetadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .clientReadOnlyMetadata)
        hasPassword = try container.decodeIfPresent(Bool.self, forKey: .hasPassword) ?? false
        otpAuthEnabled = try container.decodeIfPresent(Bool.self, forKey: .otpAuthEnabled) ?? false
        passkeyAuthEnabled = try container.decodeIfPresent(Bool.self, forKey: .passkeyAuthEnabled) ?? false
        isMultiFactorRequired = try container.decodeIfPresent(Bool.self, forKey: .isMultiFactorRequired) ?? false
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? false
        isRestricted = try container.decodeIfPresent(Bool.self, forKey: .isRestricted) ?? false
        restrictedReason = try container.decodeIfPresent(String.self, forKey: .restrictedReason)
        oauthConnections = try container.decodeIfPresent([OAuthConnection].self, forKey: .oauthConnections) ?? []
        contactChannels = try container.decodeIfPresent([ContactChannel].self, forKey: .contactChannels) ?? []
        selectedTeamId = try container.decodeIfPresent(String.self, forKey: .selectedTeamId)
        teams = try container.decodeIfPresent([TeamMembership].self, forKey: .teams) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(primaryEmail, forKey: .primaryEmail)
        try container.encode(primaryEmailVerified, forKey: .primaryEmailVerified)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(signedUpAt, forKey: .signedUpAt)
        try container.encodeIfPresent(clientMetadata, forKey: .clientMetadata)
        try container.encodeIfPresent(clientReadOnlyMetadata, forKey: .clientReadOnlyMetadata)
        try container.encode(hasPassword, forKey: .hasPassword)
        try container.encode(otpAuthEnabled, forKey: .otpAuthEnabled)
        try container.encode(passkeyAuthEnabled, forKey: .passkeyAuthEnabled)
        try container.encode(isMultiFactorRequired, forKey: .isMultiFactorRequired)
        try container.encode(isAnonymous, forKey: .isAnonymous)
        try container.encode(isRestricted, forKey: .isRestricted)
        try container.encodeIfPresent(restrictedReason, forKey: .restrictedReason)
        try container.encode(oauthConnections, forKey: .oauthConnections)
        try container.encode(contactChannels, forKey: .contactChannels)
        try container.encodeIfPresent(selectedTeamId, forKey: .selectedTeamId)
        try container.encode(teams, forKey: .teams)
    }
}

/// Represents an OAuth connection for a user
public struct OAuthConnection: Codable, Identifiable, Equatable {
    /// Unique identifier for this connection
    public let id: String

    /// The OAuth provider ID
    public let providerId: String

    /// The account ID from the OAuth provider
    public let accountId: String

    /// The user's email from the OAuth provider
    public let email: String?

    /// Display name from the OAuth provider
    public let displayName: String?

    /// Profile image URL from the OAuth provider
    public let profileImageUrl: String?

    /// When this connection was created
    public let createdAt: Date

    /// When this connection was last updated
    public let updatedAt: Date

    /// Scopes granted for this connection
    public let scopes: [String]

    /// Whether this connection has a valid access token
    public let hasAccessToken: Bool

    /// Whether this connection has a valid refresh token
    public let hasRefreshToken: Bool

    /// When the access token expires (if available)
    public let accessTokenExpiresAt: Date?

    public init(
        id: String,
        providerId: String,
        accountId: String,
        email: String?,
        displayName: String?,
        profileImageUrl: String?,
        createdAt: Date,
        updatedAt: Date,
        scopes: [String],
        hasAccessToken: Bool,
        hasRefreshToken: Bool,
        accessTokenExpiresAt: Date?
    ) {
        self.id = id
        self.providerId = providerId
        self.accountId = accountId
        self.email = email
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scopes = scopes
        self.hasAccessToken = hasAccessToken
        self.hasRefreshToken = hasRefreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
    }
}

/// Represents a team membership for a user
public struct TeamMembership: Codable, Identifiable, Equatable {
    /// Unique identifier for the team
    public let id: String

    /// Display name of the team
    public let displayName: String

    /// Profile image URL for the team
    public let profileImageUrl: String?

    /// When the user joined this team
    public let joinedAt: Date

    /// User's role in this team
    public let role: String?

    /// Custom permissions for this team membership
    public let permissions: [Permission]

    public init(
        id: String,
        displayName: String,
        profileImageUrl: String?,
        joinedAt: Date,
        role: String?,
        permissions: [Permission]
    ) {
        self.id = id
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.joinedAt = joinedAt
        self.role = role
        self.permissions = permissions
    }
}
