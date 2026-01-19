import Foundation

/// Represents a team in the Stack Auth system
public class Team: Codable, Identifiable {
    /// Reference to the app for making authenticated requests
    weak var app: StackClientApp?

    /// Unique identifier for the team
    public let id: String

    /// Display name of the team
    public var displayName: String

    /// Team description
    public var description: String?

    /// Profile image URL for the team
    public var profileImageUrl: String?

    /// When the team was created
    public let createdAt: Date

    /// When the team was last updated
    public let updatedAt: Date

    /// User ID of the team creator
    public let createdBy: String

    /// Custom metadata for the team (client-readable)
    public var clientMetadata: [String: AnyCodable]?

    /// Custom metadata for the team (server-only)
    public var serverMetadata: [String: AnyCodable]?

    /// Current members of the team
    public let members: [TeamMember]

    /// Pending invitations for the team
    public let invitations: [TeamInvitation]

    /// Team settings
    public var settings: TeamSettings?

    public init(
        id: String,
        displayName: String,
        description: String?,
        profileImageUrl: String?,
        createdAt: Date,
        updatedAt: Date,
        createdBy: String,
        clientMetadata: [String: AnyCodable]?,
        serverMetadata: [String: AnyCodable]?,
        members: [TeamMember],
        invitations: [TeamInvitation],
        settings: TeamSettings?
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.clientMetadata = clientMetadata
        self.serverMetadata = serverMetadata
        self.members = members
        self.invitations = invitations
        self.settings = settings
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        clientMetadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .clientMetadata)
        serverMetadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .serverMetadata)
        members = try container.decode([TeamMember].self, forKey: .members)
        invitations = try container.decode([TeamInvitation].self, forKey: .invitations)
        settings = try container.decodeIfPresent(TeamSettings.self, forKey: .settings)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(clientMetadata, forKey: .clientMetadata)
        try container.encodeIfPresent(serverMetadata, forKey: .serverMetadata)
        try container.encode(members, forKey: .members)
        try container.encode(invitations, forKey: .invitations)
        try container.encodeIfPresent(settings, forKey: .settings)
    }

    enum CodingKeys: String, CodingKey {
        case id, displayName, description, profileImageUrl, createdAt, updatedAt
        case createdBy, clientMetadata, serverMetadata, members, invitations, settings
    }
}

/// Represents a team member
public struct TeamMember: Codable, Identifiable, Equatable {
    /// User ID of the member
    public let id: String

    /// User's display name
    public let displayName: String?

    /// User's email
    public let email: String?

    /// User's profile image URL
    public let profileImageUrl: String?

    /// Member's role in the team
    public let role: String

    /// When the member joined the team
    public let joinedAt: Date

    /// Custom permissions for this member
    public let permissions: [Permission]

    /// Whether this member is the team owner
    public let isOwner: Bool

    /// Custom metadata for this team membership
    public let metadata: [String: AnyCodable]?

    public init(
        id: String,
        displayName: String?,
        email: String?,
        profileImageUrl: String?,
        role: String,
        joinedAt: Date,
        permissions: [Permission],
        isOwner: Bool,
        metadata: [String: AnyCodable]?
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.role = role
        self.joinedAt = joinedAt
        self.permissions = permissions
        self.isOwner = isOwner
        self.metadata = metadata
    }
}

/// Represents a pending team invitation
public struct TeamInvitation: Codable, Identifiable, Equatable {
    /// Unique identifier for the invitation
    public let id: String

    /// Email address of the invitee
    public let email: String

    /// Role the invitee will have when they accept
    public let role: String

    /// When the invitation was created
    public let createdAt: Date

    /// When the invitation expires
    public let expiresAt: Date

    /// User ID of who sent the invitation
    public let invitedBy: String

    /// Status of the invitation
    public let status: InvitationStatus

    /// Custom message included with the invitation
    public let message: String?

    /// Invitation code (for accepting the invitation)
    public let code: String?

    public init(
        id: String,
        email: String,
        role: String,
        createdAt: Date,
        expiresAt: Date,
        invitedBy: String,
        status: InvitationStatus,
        message: String?,
        code: String?
    ) {
        self.id = id
        self.email = email
        self.role = role
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.invitedBy = invitedBy
        self.status = status
        self.message = message
        self.code = code
    }

    /// Check if the invitation is still valid
    public var isValid: Bool {
        return status == .pending && expiresAt > Date()
    }
}

/// Status of a team invitation
public enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
    case expired
    case revoked
}

/// Team settings
public struct TeamSettings: Codable, Equatable {
    /// Whether members can invite others
    public let membersCanInvite: Bool

    /// Whether the team is publicly visible
    public let isPublic: Bool

    /// Default role for new members
    public let defaultMemberRole: String

    /// Maximum number of members allowed
    public let maxMembers: Int?

    /// Whether to require email verification for invitations
    public let requireEmailVerification: Bool

    /// Custom domain for team (if applicable)
    public let customDomain: String?

    public init(
        membersCanInvite: Bool,
        isPublic: Bool,
        defaultMemberRole: String,
        maxMembers: Int?,
        requireEmailVerification: Bool,
        customDomain: String?
    ) {
        self.membersCanInvite = membersCanInvite
        self.isPublic = isPublic
        self.defaultMemberRole = defaultMemberRole
        self.maxMembers = maxMembers
        self.requireEmailVerification = requireEmailVerification
        self.customDomain = customDomain
    }
}

/// Request to create a new team
public struct CreateTeamRequest: Codable, Equatable {
    /// Display name for the team
    public let displayName: String

    /// Team description
    public let description: String?

    /// Profile image URL
    public let profileImageUrl: String?

    /// Client metadata
    public let clientMetadata: [String: AnyCodable]?

    /// Initial team settings
    public let settings: TeamSettings?

    public init(
        displayName: String,
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

/// Request to update a team
public struct UpdateTeamRequest: Codable, Equatable {
    /// Updated display name
    public let displayName: String?

    /// Updated description
    public let description: String?

    /// Updated profile image URL
    public let profileImageUrl: String?

    /// Updated client metadata
    public let clientMetadata: [String: AnyCodable]?

    /// Updated team settings
    public let settings: TeamSettings?

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

/// Request to invite a user to a team
public struct InviteTeamMemberRequest: Codable, Equatable {
    /// Email address of the invitee
    public let email: String

    /// Role to assign
    public let role: String

    /// Optional custom message
    public let message: String?

    /// Custom expiration time (defaults to project settings)
    public let expiresAt: Date?

    public init(
        email: String,
        role: String,
        message: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.email = email
        self.role = role
        self.message = message
        self.expiresAt = expiresAt
    }
}
