import Foundation

/// Base error type for all Stack Auth API errors
public struct StackAuthAPIError: Error, Codable {
    public let code: String
    public let message: String
    public let details: [String: AnyCodable]?

    public init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

extension StackAuthAPIError: LocalizedError {
    public var errorDescription: String? {
        return message
    }
}

/// Type-erased wrapper for Codable values
public struct AnyCodable: Codable, Equatable, Hashable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let bool as Bool: hasher.combine(bool)
        case let int as Int: hasher.combine(int)
        case let double as Double: hasher.combine(double)
        case let string as String: hasher.combine(string)
        default: hasher.combine(0)
        }
    }
}

// Specific error types
extension StackAuthAPIError {
    public static func userNotSignedIn() -> StackAuthAPIError {
        StackAuthAPIError(code: "user_not_signed_in", message: "User is not signed in but getUser was called with { or: 'throw' }.")
    }

    public static func emailPasswordMismatch() -> StackAuthAPIError {
        StackAuthAPIError(code: "email_password_mismatch", message: "The email and password combination is incorrect.")
    }

    public static func userWithEmailAlreadyExists() -> StackAuthAPIError {
        StackAuthAPIError(code: "user_email_already_exists", message: "A user with this email address already exists.")
    }

    public static func passwordRequirementsNotMet() -> StackAuthAPIError {
        StackAuthAPIError(code: "password_requirements_not_met", message: "The password does not meet the project's requirements.")
    }

    public static func multiFactorAuthenticationRequired(attemptCode: String) -> StackAuthAPIError {
        StackAuthAPIError(
            code: "multi_factor_authentication_required",
            message: "Multi-factor authentication is required.",
            details: ["attempt_code": AnyCodable(attemptCode)]
        )
    }

    public static func passwordResetCodeInvalid() -> StackAuthAPIError {
        StackAuthAPIError(code: "password_reset_code_invalid", message: "The password reset code is invalid or has expired.")
    }

    public static func magicLinkCodeInvalid() -> StackAuthAPIError {
        StackAuthAPIError(code: "magic_link_code_invalid", message: "The magic link code is invalid or has expired.")
    }

    public static func invalidTotpCode() -> StackAuthAPIError {
        StackAuthAPIError(code: "invalid_totp_code", message: "The MFA code is incorrect. Please try again.")
    }

    public static func mfaAttemptCodeInvalid() -> StackAuthAPIError {
        StackAuthAPIError(code: "mfa_attempt_code_invalid", message: "The MFA attempt has expired. Please sign in again.")
    }

    public static func emailVerificationCodeInvalid() -> StackAuthAPIError {
        StackAuthAPIError(code: "email_verification_code_invalid", message: "The email verification code is invalid or has expired.")
    }

    public static func teamInvitationCodeInvalid() -> StackAuthAPIError {
        StackAuthAPIError(code: "team_invitation_code_invalid", message: "The team invitation code is invalid or has expired.")
    }

    public static func passwordConfirmationMismatch() -> StackAuthAPIError {
        StackAuthAPIError(code: "password_confirmation_mismatch", message: "The current password is incorrect.")
    }

    public static func oauthProviderAccountIdAlreadyUsedForSignIn() -> StackAuthAPIError {
        StackAuthAPIError(code: "oauth_provider_account_id_already_used_for_sign_in", message: "This OAuth account is already linked to another user for sign-in.")
    }

    public static func oauthConnectionNotConnected() -> StackAuthAPIError {
        StackAuthAPIError(code: "oauth_connection_not_connected", message: "You don't have this OAuth provider connected.")
    }

    public static func oauthConnectionTokenExpired() -> StackAuthAPIError {
        StackAuthAPIError(code: "oauth_connection_token_expired", message: "The OAuth token has expired and cannot be refreshed. Please reconnect.")
    }

    public static func oauthScopeNotGranted() -> StackAuthAPIError {
        StackAuthAPIError(code: "oauth_scope_not_granted", message: "The connected OAuth account doesn't have the required permissions.")
    }

    public static func userNotFound() -> StackAuthAPIError {
        StackAuthAPIError(code: "user_not_found", message: "No user with this email address was found.")
    }

    public static func redirectUrlNotWhitelisted() -> StackAuthAPIError {
        StackAuthAPIError(code: "redirect_url_not_whitelisted", message: "The callback URL is not in the project's trusted domains list.")
    }
}
