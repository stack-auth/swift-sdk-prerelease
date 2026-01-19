import Foundation

/// Represents an authentication session
public struct AuthSession: Codable {
    /// Access token for API requests
    public let accessToken: String

    /// Refresh token for obtaining new access tokens
    public let refreshToken: String?

    /// When the access token expires
    public let expiresAt: Date

    /// Token type (typically "Bearer")
    public let tokenType: String

    /// User associated with this session
    public let user: BaseUser

    /// Session metadata
    public let metadata: [String: AnyCodable]?

    public init(
        accessToken: String,
        refreshToken: String?,
        expiresAt: Date,
        tokenType: String,
        user: BaseUser,
        metadata: [String: AnyCodable]?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.user = user
        self.metadata = metadata
    }

    /// Check if the access token is expired
    public var isExpired: Bool {
        return Date() >= expiresAt
    }

    /// Time remaining until token expiration in seconds
    public var timeUntilExpiration: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}

/// Request to sign in with email and password
public struct SignInWithPasswordRequest: Codable, Equatable {
    /// User's email address
    public let email: String

    /// User's password
    public let password: String

    /// Whether to remember this session
    public let rememberMe: Bool

    public init(
        email: String,
        password: String,
        rememberMe: Bool = false
    ) {
        self.email = email
        self.password = password
        self.rememberMe = rememberMe
    }
}

/// Response from sign in attempt that may require MFA
public struct SignInResponse: Codable {
    /// Whether MFA is required
    public let requiresMfa: Bool

    /// MFA attempt code (if MFA is required)
    public let mfaAttemptCode: String?

    /// Available MFA methods
    public let mfaMethods: [MFAMethod]?

    /// Authentication session (if MFA is not required)
    public let session: AuthSession?

    public init(
        requiresMfa: Bool,
        mfaAttemptCode: String?,
        mfaMethods: [MFAMethod]?,
        session: AuthSession?
    ) {
        self.requiresMfa = requiresMfa
        self.mfaAttemptCode = mfaAttemptCode
        self.mfaMethods = mfaMethods
        self.session = session
    }
}

/// Available MFA methods
public enum MFAMethod: String, Codable {
    case totp
    case sms
    case email
    case backup_codes
}

/// Request to sign up with email and password
public struct SignUpWithPasswordRequest: Codable {
    /// User's email address
    public let email: String

    /// User's password
    public let password: String

    /// User's display name
    public let displayName: String?

    /// Profile image URL
    public let profileImageUrl: String?

    /// Client metadata
    public let clientMetadata: [String: AnyCodable]?

    public init(
        email: String,
        password: String,
        displayName: String? = nil,
        profileImageUrl: String? = nil,
        clientMetadata: [String: AnyCodable]? = nil
    ) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.clientMetadata = clientMetadata
    }
}

/// Request to send a magic link
public struct SendMagicLinkRequest: Codable, Equatable {
    /// Email address to send the magic link to
    public let email: String

    /// Callback URL after successful authentication
    public let callbackUrl: String?

    /// Whether to create a new user if one doesn't exist
    public let createUserIfNotExists: Bool

    public init(
        email: String,
        callbackUrl: String? = nil,
        createUserIfNotExists: Bool = true
    ) {
        self.email = email
        self.callbackUrl = callbackUrl
        self.createUserIfNotExists = createUserIfNotExists
    }
}

/// Request to verify a magic link code
public struct VerifyMagicLinkRequest: Codable, Equatable {
    /// The magic link code
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

/// Request to reset password
public struct PasswordResetRequest: Codable, Equatable {
    /// Email address of the user
    public let email: String

    /// Callback URL after successful password reset
    public let callbackUrl: String?

    public init(
        email: String,
        callbackUrl: String? = nil
    ) {
        self.email = email
        self.callbackUrl = callbackUrl
    }
}

/// Request to verify password reset code and set new password
public struct VerifyPasswordResetRequest: Codable, Equatable {
    /// The password reset code
    public let code: String

    /// The new password
    public let newPassword: String

    public init(
        code: String,
        newPassword: String
    ) {
        self.code = code
        self.newPassword = newPassword
    }
}

/// Request to verify MFA code
public struct VerifyMFARequest: Codable, Equatable {
    /// The MFA attempt code from initial sign-in
    public let attemptCode: String

    /// The MFA code from the user's authenticator
    public let code: String

    /// MFA method being used
    public let method: MFAMethod

    public init(
        attemptCode: String,
        code: String,
        method: MFAMethod
    ) {
        self.attemptCode = attemptCode
        self.code = code
        self.method = method
    }
}

/// Request to refresh an access token
public struct RefreshTokenRequest: Codable, Equatable {
    /// The refresh token
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

/// Response from token refresh
public struct RefreshTokenResponse: Codable, Equatable {
    /// New access token
    public let accessToken: String

    /// New refresh token (if rotation is enabled)
    public let refreshToken: String?

    /// When the new access token expires
    public let expiresAt: Date

    /// Token type
    public let tokenType: String

    public init(
        accessToken: String,
        refreshToken: String?,
        expiresAt: Date,
        tokenType: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.tokenType = tokenType
    }
}

/// OAuth authorization URL response
public struct OAuthAuthorizationUrlResponse: Codable, Equatable {
    /// The authorization URL to redirect the user to
    public let authorizationUrl: String

    /// State parameter for CSRF protection
    public let state: String

    /// Code verifier for PKCE (if applicable)
    public let codeVerifier: String?

    public init(
        authorizationUrl: String,
        state: String,
        codeVerifier: String?
    ) {
        self.authorizationUrl = authorizationUrl
        self.state = state
        self.codeVerifier = codeVerifier
    }
}

/// Request to handle OAuth callback
public struct OAuthCallbackRequest: Codable, Equatable {
    /// OAuth provider ID
    public let providerId: String

    /// Authorization code from the OAuth provider
    public let code: String

    /// State parameter for CSRF protection
    public let state: String

    /// Code verifier for PKCE (if applicable)
    public let codeVerifier: String?

    public init(
        providerId: String,
        code: String,
        state: String,
        codeVerifier: String?
    ) {
        self.providerId = providerId
        self.code = code
        self.state = state
        self.codeVerifier = codeVerifier
    }
}

/// Email verification request
public struct VerifyEmailRequest: Codable, Equatable {
    /// Email verification code
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

/// Request to send email verification
public struct SendEmailVerificationRequest: Codable, Equatable {
    /// Email address to verify
    public let email: String

    /// Callback URL after verification
    public let callbackUrl: String?

    public init(
        email: String,
        callbackUrl: String? = nil
    ) {
        self.email = email
        self.callbackUrl = callbackUrl
    }
}
