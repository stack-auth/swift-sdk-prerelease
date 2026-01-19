import Foundation

/// Represents a permission granted to a user or team
public struct Permission: Codable, Identifiable, Equatable {
    /// Unique identifier for the permission
    public let id: String

    /// The scope of this permission (e.g., "user:read", "admin:write")
    public let scope: String

    /// The resource this permission applies to (optional)
    public let resource: String?

    /// The action this permission allows (e.g., "read", "write", "delete")
    public let action: String?

    /// When this permission was granted
    public let grantedAt: Date

    /// When this permission expires (if applicable)
    public let expiresAt: Date?

    /// Who granted this permission
    public let grantedBy: String?

    /// Additional metadata about the permission
    public let metadata: [String: AnyCodable]?

    public init(
        id: String,
        scope: String,
        resource: String?,
        action: String?,
        grantedAt: Date,
        expiresAt: Date?,
        grantedBy: String?,
        metadata: [String: AnyCodable]?
    ) {
        self.id = id
        self.scope = scope
        self.resource = resource
        self.action = action
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.grantedBy = grantedBy
        self.metadata = metadata
    }

    /// Check if this permission is currently valid (not expired)
    public var isValid: Bool {
        guard let expiresAt = expiresAt else {
            return true
        }
        return expiresAt > Date()
    }

    /// Check if this permission matches a given scope
    public func matches(scope: String) -> Bool {
        return self.scope == scope || self.scope == "*"
    }

    /// Check if this permission allows a specific action
    public func allows(action: String) -> Bool {
        guard isValid else {
            return false
        }

        if let permissionAction = self.action {
            return permissionAction == action || permissionAction == "*"
        }

        // If no specific action is set, check if the scope includes the action
        return scope.hasSuffix(":\(action)") || scope.hasSuffix(":*")
    }

    /// Check if this permission applies to a specific resource
    public func appliesTo(resource: String) -> Bool {
        guard let permissionResource = self.resource else {
            return true // No resource restriction
        }
        return permissionResource == resource || permissionResource == "*"
    }
}

/// Definition of a permission that can be granted
public struct PermissionDefinition: Codable, Identifiable, Equatable {
    /// Unique identifier for the permission definition
    public let id: String

    /// The scope identifier (e.g., "user:read", "admin:write")
    public let scope: String

    /// Human-readable name for the permission
    public let displayName: String

    /// Description of what this permission allows
    public let description: String?

    /// Category this permission belongs to
    public let category: String?

    /// Whether this is a system-level permission
    public let isSystemPermission: Bool

    /// Whether this permission is deprecated
    @available(*, deprecated, message: "This permission definition is deprecated")
    public let isDeprecated: Bool

    /// Default expiration duration in seconds (optional)
    public let defaultExpirationSeconds: Int?

    /// Required parent permissions
    public let requiredPermissions: [String]

    /// When this permission definition was created
    public let createdAt: Date

    /// When this permission definition was last updated
    public let updatedAt: Date

    public init(
        id: String,
        scope: String,
        displayName: String,
        description: String?,
        category: String?,
        isSystemPermission: Bool,
        isDeprecated: Bool,
        defaultExpirationSeconds: Int?,
        requiredPermissions: [String],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.scope = scope
        self.displayName = displayName
        self.description = description
        self.category = category
        self.isSystemPermission = isSystemPermission
        self.isDeprecated = isDeprecated
        self.defaultExpirationSeconds = defaultExpirationSeconds
        self.requiredPermissions = requiredPermissions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Request to grant a permission
public struct PermissionGrantRequest: Codable, Equatable {
    /// The scope to grant
    public let scope: String

    /// The resource to grant access to (optional)
    public let resource: String?

    /// The specific action to allow (optional)
    public let action: String?

    /// When the permission should expire (optional)
    public let expiresAt: Date?

    /// Additional metadata
    public let metadata: [String: AnyCodable]?

    public init(
        scope: String,
        resource: String? = nil,
        action: String? = nil,
        expiresAt: Date? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.scope = scope
        self.resource = resource
        self.action = action
        self.expiresAt = expiresAt
        self.metadata = metadata
    }
}

/// Result of checking permissions
public struct PermissionCheckResult: Codable, Equatable {
    /// Whether the permission check passed
    public let granted: Bool

    /// Reason for denial (if applicable)
    public let reason: String?

    /// Matching permissions that satisfied the check
    public let matchingPermissions: [Permission]

    public init(
        granted: Bool,
        reason: String?,
        matchingPermissions: [Permission]
    ) {
        self.granted = granted
        self.reason = reason
        self.matchingPermissions = matchingPermissions
    }
}

/// Role definition with associated permissions
public struct Role: Codable, Identifiable, Equatable {
    /// Unique identifier for the role
    public let id: String

    /// Name of the role
    public let name: String

    /// Description of the role
    public let description: String?

    /// Permissions included in this role
    public let permissions: [String]

    /// Whether this is a system role (cannot be modified)
    public let isSystemRole: Bool

    /// Priority/rank of this role (higher = more privileged)
    public let priority: Int

    /// When this role was created
    public let createdAt: Date

    /// When this role was last updated
    public let updatedAt: Date

    public init(
        id: String,
        name: String,
        description: String?,
        permissions: [String],
        isSystemRole: Bool,
        priority: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.permissions = permissions
        self.isSystemRole = isSystemRole
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
