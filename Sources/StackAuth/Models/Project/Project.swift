import Foundation

/// Represents a Stack Auth project configuration
public struct Project: Codable, Identifiable, Equatable {
    /// Unique identifier for the project
    public let id: String

    /// Display name of the project
    public let displayName: String

    /// Project description
    public let description: String?

    /// When the project was created
    public let createdAt: Date

    /// When the project was last updated
    public let updatedAt: Date

    /// Whether the project is in production mode
    public let isProductionMode: Bool

    /// Configuration for authentication
    public let config: ProjectConfig

    /// Email service provider configuration
    public let emailConfig: EmailServiceConfig?

    /// OAuth provider configurations
    public let oauthProviders: [OAuthProviderConfig]

    /// List of trusted callback URLs/domains
    public let trustedDomains: [String]

    /// Whether to allow localhost for development
    public let allowLocalhost: Bool

    public init(
        id: String,
        displayName: String,
        description: String?,
        createdAt: Date,
        updatedAt: Date,
        isProductionMode: Bool,
        config: ProjectConfig,
        emailConfig: EmailServiceConfig?,
        oauthProviders: [OAuthProviderConfig],
        trustedDomains: [String],
        allowLocalhost: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isProductionMode = isProductionMode
        self.config = config
        self.emailConfig = emailConfig
        self.oauthProviders = oauthProviders
        self.trustedDomains = trustedDomains
        self.allowLocalhost = allowLocalhost
    }
}

/// Project configuration settings
public struct ProjectConfig: Codable, Equatable {
    /// Authentication method configurations
    public let authMethods: AuthMethodsConfig

    /// Multi-factor authentication configuration
    public let mfaConfig: MFAConfig

    /// Session configuration
    public let sessionConfig: SessionConfig

    /// Magic link configuration
    public let magicLinkConfig: MagicLinkConfig?

    /// Password configuration
    public let passwordConfig: PasswordConfig?

    /// Team configuration
    public let teamConfig: TeamConfig?

    /// Whether to allow account deletion
    public let allowAccountDeletion: Bool

    /// Custom metadata schema for users
    public let userMetadataSchema: [String: MetadataFieldSchema]?

    public init(
        authMethods: AuthMethodsConfig,
        mfaConfig: MFAConfig,
        sessionConfig: SessionConfig,
        magicLinkConfig: MagicLinkConfig?,
        passwordConfig: PasswordConfig?,
        teamConfig: TeamConfig?,
        allowAccountDeletion: Bool,
        userMetadataSchema: [String: MetadataFieldSchema]?
    ) {
        self.authMethods = authMethods
        self.mfaConfig = mfaConfig
        self.sessionConfig = sessionConfig
        self.magicLinkConfig = magicLinkConfig
        self.passwordConfig = passwordConfig
        self.teamConfig = teamConfig
        self.allowAccountDeletion = allowAccountDeletion
        self.userMetadataSchema = userMetadataSchema
    }
}

/// Authentication methods configuration
public struct AuthMethodsConfig: Codable, Equatable {
    /// Whether password authentication is enabled
    public let password: Bool

    /// Whether magic link authentication is enabled
    public let magicLink: Bool

    /// Whether OAuth authentication is enabled
    public let oauth: Bool

    /// Whether guest/anonymous authentication is enabled
    public let guest: Bool

    public init(
        password: Bool,
        magicLink: Bool,
        oauth: Bool,
        guest: Bool
    ) {
        self.password = password
        self.magicLink = magicLink
        self.oauth = oauth
        self.guest = guest
    }
}

/// Multi-factor authentication configuration
public struct MFAConfig: Codable, Equatable {
    /// Whether MFA is required for all users
    public let required: Bool

    /// Whether TOTP (authenticator app) is enabled
    public let totpEnabled: Bool

    /// Whether SMS MFA is enabled
    public let smsEnabled: Bool

    /// Issuer name for TOTP (displayed in authenticator apps)
    public let totpIssuer: String?

    public init(
        required: Bool,
        totpEnabled: Bool,
        smsEnabled: Bool,
        totpIssuer: String?
    ) {
        self.required = required
        self.totpEnabled = totpEnabled
        self.smsEnabled = smsEnabled
        self.totpIssuer = totpIssuer
    }
}

/// Session configuration
public struct SessionConfig: Codable, Equatable {
    /// Session duration in seconds
    public let sessionDurationSeconds: Int

    /// Refresh token duration in seconds
    public let refreshTokenDurationSeconds: Int

    /// Whether to automatically extend sessions
    public let autoExtendSessions: Bool

    public init(
        sessionDurationSeconds: Int,
        refreshTokenDurationSeconds: Int,
        autoExtendSessions: Bool
    ) {
        self.sessionDurationSeconds = sessionDurationSeconds
        self.refreshTokenDurationSeconds = refreshTokenDurationSeconds
        self.autoExtendSessions = autoExtendSessions
    }
}

/// Magic link configuration
public struct MagicLinkConfig: Codable, Equatable {
    /// Whether magic links are enabled
    public let enabled: Bool

    /// Magic link expiration time in seconds
    public let expirationSeconds: Int

    /// Custom email template for magic links
    public let emailTemplate: String?

    public init(
        enabled: Bool,
        expirationSeconds: Int,
        emailTemplate: String?
    ) {
        self.enabled = enabled
        self.expirationSeconds = expirationSeconds
        self.emailTemplate = emailTemplate
    }
}

/// Password configuration
public struct PasswordConfig: Codable, Equatable {
    /// Minimum password length
    public let minLength: Int

    /// Maximum password length
    public let maxLength: Int

    /// Whether to require uppercase letters
    public let requireUppercase: Bool

    /// Whether to require lowercase letters
    public let requireLowercase: Bool

    /// Whether to require numbers
    public let requireNumbers: Bool

    /// Whether to require special characters
    public let requireSpecialCharacters: Bool

    /// Password reset expiration time in seconds
    public let resetExpirationSeconds: Int

    public init(
        minLength: Int,
        maxLength: Int,
        requireUppercase: Bool,
        requireLowercase: Bool,
        requireNumbers: Bool,
        requireSpecialCharacters: Bool,
        resetExpirationSeconds: Int
    ) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.requireUppercase = requireUppercase
        self.requireLowercase = requireLowercase
        self.requireNumbers = requireNumbers
        self.requireSpecialCharacters = requireSpecialCharacters
        self.resetExpirationSeconds = resetExpirationSeconds
    }
}

/// Team configuration
public struct TeamConfig: Codable, Equatable {
    /// Whether teams are enabled
    public let enabled: Bool

    /// Whether users can create teams
    public let allowUserCreation: Bool

    /// Maximum number of teams per user
    public let maxTeamsPerUser: Int?

    /// Default role for new team members
    public let defaultRole: String?

    /// Whether team invitations require email verification
    public let requireEmailVerification: Bool

    public init(
        enabled: Bool,
        allowUserCreation: Bool,
        maxTeamsPerUser: Int?,
        defaultRole: String?,
        requireEmailVerification: Bool
    ) {
        self.enabled = enabled
        self.allowUserCreation = allowUserCreation
        self.maxTeamsPerUser = maxTeamsPerUser
        self.defaultRole = defaultRole
        self.requireEmailVerification = requireEmailVerification
    }
}

/// Email service provider configuration
public struct EmailServiceConfig: Codable, Equatable {
    /// Email service provider type
    public let provider: EmailServiceProvider

    /// Sender email address
    public let fromEmail: String

    /// Sender name
    public let fromName: String?

    /// Whether the email service is configured and active
    public let isConfigured: Bool

    public init(
        provider: EmailServiceProvider,
        fromEmail: String,
        fromName: String?,
        isConfigured: Bool
    ) {
        self.provider = provider
        self.fromEmail = fromEmail
        self.fromName = fromName
        self.isConfigured = isConfigured
    }
}

/// Email service provider type
public enum EmailServiceProvider: String, Codable {
    case sendgrid
    case mailgun
    case ses
    case smtp
    case stackDefault = "stack_default"
}

/// OAuth provider configuration
public struct OAuthProviderConfig: Codable, Identifiable, Equatable {
    /// Unique identifier for the OAuth provider
    public let id: String

    /// OAuth provider type
    public let type: OAuthProviderType

    /// Whether this provider is enabled
    public let enabled: Bool

    /// Client ID for this OAuth provider
    public let clientId: String

    /// Scopes to request from this provider
    public let scopes: [String]

    /// Display name for this provider
    public let displayName: String?

    public init(
        id: String,
        type: OAuthProviderType,
        enabled: Bool,
        clientId: String,
        scopes: [String],
        displayName: String?
    ) {
        self.id = id
        self.type = type
        self.enabled = enabled
        self.clientId = clientId
        self.scopes = scopes
        self.displayName = displayName
    }
}

/// OAuth provider type
public enum OAuthProviderType: String, Codable {
    case google
    case github
    case facebook
    case microsoft
    case apple
    case discord
    case spotify
    case twitch
    case linkedin
    case twitter
    case gitlab
    case custom
}

/// Metadata field schema definition
public struct MetadataFieldSchema: Codable, Equatable {
    /// Field type
    public let type: MetadataFieldType

    /// Whether the field is required
    public let required: Bool

    /// Default value for the field
    public let defaultValue: AnyCodable?

    /// Validation rules for the field
    public let validation: MetadataFieldValidation?

    public init(
        type: MetadataFieldType,
        required: Bool,
        defaultValue: AnyCodable?,
        validation: MetadataFieldValidation?
    ) {
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.validation = validation
    }
}

/// Metadata field type
public enum MetadataFieldType: String, Codable {
    case string
    case number
    case boolean
    case array
    case object
    case date
}

/// Metadata field validation rules
public struct MetadataFieldValidation: Codable, Equatable {
    /// Minimum value (for numbers)
    public let min: Double?

    /// Maximum value (for numbers)
    public let max: Double?

    /// Minimum length (for strings and arrays)
    public let minLength: Int?

    /// Maximum length (for strings and arrays)
    public let maxLength: Int?

    /// Regular expression pattern (for strings)
    public let pattern: String?

    /// Allowed values (enum)
    public let enumValues: [AnyCodable]?

    public init(
        min: Double?,
        max: Double?,
        minLength: Int?,
        maxLength: Int?,
        pattern: String?,
        enumValues: [AnyCodable]?
    ) {
        self.min = min
        self.max = max
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.enumValues = enumValues
    }
}
