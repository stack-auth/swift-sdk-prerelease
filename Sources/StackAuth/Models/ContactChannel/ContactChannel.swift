import Foundation

/// Represents a contact channel (email or phone) for a user
public class ContactChannel: Codable, Identifiable {
    /// Reference to the app for making authenticated requests
    weak var app: StackClientApp?

    /// Unique identifier for this contact channel
    public let id: String

    /// Type of contact channel (email, phone)
    public let type: ContactChannelType

    /// The contact value (email address or phone number)
    public let value: String

    /// Whether this contact channel has been verified
    public let isVerified: Bool

    /// Whether this is the primary contact channel
    public let isPrimary: Bool

    /// When this contact channel was created
    public let createdAt: Date

    /// When this contact channel was last updated
    public let updatedAt: Date

    /// When this contact channel was verified (if applicable)
    public let verifiedAt: Date?

    /// Whether this contact channel can be used for authentication
    public let usedForAuth: Bool

    public init(
        id: String,
        type: ContactChannelType,
        value: String,
        isVerified: Bool,
        isPrimary: Bool,
        createdAt: Date,
        updatedAt: Date,
        verifiedAt: Date?,
        usedForAuth: Bool
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.isVerified = isVerified
        self.isPrimary = isPrimary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.verifiedAt = verifiedAt
        self.usedForAuth = usedForAuth
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(ContactChannelType.self, forKey: .type)
        self.value = try container.decode(String.self, forKey: .value)
        self.isVerified = try container.decode(Bool.self, forKey: .isVerified)
        self.isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.verifiedAt = try container.decodeIfPresent(Date.self, forKey: .verifiedAt)
        self.usedForAuth = try container.decode(Bool.self, forKey: .usedForAuth)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(verifiedAt, forKey: .verifiedAt)
        try container.encode(usedForAuth, forKey: .usedForAuth)
    }

    enum CodingKeys: String, CodingKey {
        case id, type, value, isVerified, isPrimary, createdAt, updatedAt, verifiedAt, usedForAuth
    }
}

/// Type of contact channel
public enum ContactChannelType: String, Codable {
    case email
    case phone
}
