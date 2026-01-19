import Foundation

/// MFA configuration for a user
public struct UserMFAConfig: Codable, Equatable {
    /// Whether MFA is enabled for this user
    public let enabled: Bool

    /// Configured MFA methods
    public let methods: [UserMFAMethod]

    /// Whether the user has backup codes
    public let hasBackupCodes: Bool

    /// Number of remaining backup codes
    public let remainingBackupCodes: Int

    public init(
        enabled: Bool,
        methods: [UserMFAMethod],
        hasBackupCodes: Bool,
        remainingBackupCodes: Int
    ) {
        self.enabled = enabled
        self.methods = methods
        self.hasBackupCodes = hasBackupCodes
        self.remainingBackupCodes = remainingBackupCodes
    }
}

/// MFA method configured for a user
public struct UserMFAMethod: Codable, Identifiable, Equatable {
    /// Unique identifier for this MFA method
    public let id: String

    /// Type of MFA method
    public let type: MFAMethod

    /// Whether this is the primary MFA method
    public let isPrimary: Bool

    /// When this method was added
    public let createdAt: Date

    /// When this method was last used
    public let lastUsedAt: Date?

    /// Display name for this method (e.g., phone number for SMS)
    public let displayName: String?

    public init(
        id: String,
        type: MFAMethod,
        isPrimary: Bool,
        createdAt: Date,
        lastUsedAt: Date?,
        displayName: String?
    ) {
        self.id = id
        self.type = type
        self.isPrimary = isPrimary
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.displayName = displayName
    }
}

/// Request to enable TOTP MFA
public struct EnableTOTPRequest: Codable, Equatable {
    /// Optional device name for this TOTP configuration
    public let deviceName: String?

    public init(deviceName: String? = nil) {
        self.deviceName = deviceName
    }
}

/// Response from TOTP enrollment initiation
public struct TOTPEnrollmentResponse: Codable, Equatable {
    /// Secret key for the authenticator app
    public let secret: String

    /// QR code data URL for easy scanning
    public let qrCodeDataUrl: String

    /// Manual entry URL (otpauth://)
    public let otpauthUrl: String

    /// Issuer name displayed in the authenticator app
    public let issuer: String

    /// Account name displayed in the authenticator app
    public let accountName: String

    public init(
        secret: String,
        qrCodeDataUrl: String,
        otpauthUrl: String,
        issuer: String,
        accountName: String
    ) {
        self.secret = secret
        self.qrCodeDataUrl = qrCodeDataUrl
        self.otpauthUrl = otpauthUrl
        self.issuer = issuer
        self.accountName = accountName
    }
}

/// Request to verify and complete TOTP enrollment
public struct VerifyTOTPEnrollmentRequest: Codable, Equatable {
    /// TOTP code from the authenticator app
    public let code: String

    /// The secret that was provided during enrollment
    public let secret: String

    public init(
        code: String,
        secret: String
    ) {
        self.code = code
        self.secret = secret
    }
}

/// Response from completing TOTP enrollment
public struct TOTPEnrollmentCompleteResponse: Codable, Equatable {
    /// The MFA method that was created
    public let method: UserMFAMethod

    /// Backup codes for account recovery
    public let backupCodes: [String]

    public init(
        method: UserMFAMethod,
        backupCodes: [String]
    ) {
        self.method = method
        self.backupCodes = backupCodes
    }
}

/// Request to enable SMS MFA
public struct EnableSMSMFARequest: Codable, Equatable {
    /// Phone number to send codes to
    public let phoneNumber: String

    public init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
}

/// Response from SMS MFA enrollment initiation
public struct SMSMFAEnrollmentResponse: Codable, Equatable {
    /// The phone number that will receive codes
    public let phoneNumber: String

    /// Verification ID for completing enrollment
    public let verificationId: String

    public init(
        phoneNumber: String,
        verificationId: String
    ) {
        self.phoneNumber = phoneNumber
        self.verificationId = verificationId
    }
}

/// Request to verify and complete SMS MFA enrollment
public struct VerifySMSMFAEnrollmentRequest: Codable, Equatable {
    /// Verification ID from enrollment initiation
    public let verificationId: String

    /// SMS code sent to the phone
    public let code: String

    public init(
        verificationId: String,
        code: String
    ) {
        self.verificationId = verificationId
        self.code = code
    }
}

/// Request to disable an MFA method
public struct DisableMFAMethodRequest: Codable, Equatable {
    /// ID of the MFA method to disable
    public let methodId: String

    /// Current password for confirmation
    public let password: String?

    public init(
        methodId: String,
        password: String? = nil
    ) {
        self.methodId = methodId
        self.password = password
    }
}

/// Request to regenerate backup codes
public struct RegenerateBackupCodesRequest: Codable, Equatable {
    /// Current password for confirmation
    public let password: String?

    public init(password: String? = nil) {
        self.password = password
    }
}

/// Response with backup codes
public struct BackupCodesResponse: Codable, Equatable {
    /// List of backup codes
    public let codes: [String]

    /// When these codes were generated
    public let generatedAt: Date

    public init(
        codes: [String],
        generatedAt: Date
    ) {
        self.codes = codes
        self.generatedAt = generatedAt
    }
}
