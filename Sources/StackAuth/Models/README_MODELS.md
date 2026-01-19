# Stack Auth Swift SDK - Models Documentation

This directory contains all the model types for the Stack Auth Swift SDK.

## Overview

The Stack Auth SDK models are organized into the following categories:

- **User** - Core user types and authentication identity
- **Auth** - Authentication sessions, sign-in/sign-up requests, MFA
- **Permission** - Access control, permissions, and roles
- **Team** - Team management, members, and invitations
- **Project** - Project configuration and settings
- **ContactChannel** - User contact methods (email, phone)
- **Payments** - Subscriptions, payment methods, invoices

## Total Types: 74

All models conform to:
- `Codable` for JSON serialization/deserialization
- `Identifiable` (where applicable) for SwiftUI compatibility
- `Equatable` for value comparison

## Key Models

### BaseUser
The core user model containing all user properties:
```swift
let user: BaseUser
print(user.displayName)
print(user.primaryEmail)
print(user.isGuest)
print(user.hasMfaEnabled)
```

### AuthSession
Active authentication session with access/refresh tokens:
```swift
let session: AuthSession
print(session.accessToken)
print(session.isExpired)
print(session.timeUntilExpiration)
```

### Permission
Permission model with helper methods:
```swift
let permission: Permission
print(permission.isValid)
print(permission.matches(scope: "admin:write"))
print(permission.allows(action: "delete"))
```

### Team
Team entity with members and settings:
```swift
let team: Team
print(team.displayName)
print(team.members.count)
print(team.settings?.membersCanInvite)
```

### Project
Project configuration:
```swift
let project: Project
print(project.config.authMethods.password)
print(project.config.mfaConfig.required)
print(project.oauthProviders.map { $0.type })
```

### Subscription
User or team subscription:
```swift
let subscription: Subscription
print(subscription.isActive)
print(subscription.isTrialing)
print(subscription.planName)
```

## Features

### Automatic JSON Decoding
Models automatically decode from JSON with snake_case to camelCase conversion:
```swift
// JSON: {"created_at": "2025-01-19T00:00:00Z", "display_name": "John Doe"}
// Swift: user.createdAt, user.displayName
```

### Date Handling
All Date properties automatically decode from ISO8601 strings via the APIClient configuration.

### Metadata Support
User and team metadata uses `AnyCodable` for flexible JSON structures:
```swift
let metadata: [String: AnyCodable] = [
    "preferences": AnyCodable(["theme": "dark"]),
    "age": AnyCodable(25),
    "active": AnyCodable(true)
]
```

### Helper Methods
Many models include convenience methods:
```swift
// Check if expired
if session.isExpired {
    // Refresh token
}

// Check permissions
if permission.allows(action: "write") && permission.appliesTo(resource: "documents") {
    // Allow action
}

// Check subscription status
if subscription.isActive && !subscription.isTrialing {
    // Full subscription active
}

// Check card expiration
if paymentMethod.card?.isExpired == true {
    // Update payment method
}
```

## Request/Response Types

The SDK includes dedicated types for API requests and responses:

### Authentication
- `SignInWithPasswordRequest`
- `SignUpWithPasswordRequest`
- `SendMagicLinkRequest`
- `VerifyMagicLinkRequest`
- `PasswordResetRequest`
- `VerifyPasswordResetRequest`
- `RefreshTokenRequest`
- `OAuthCallbackRequest`

### MFA
- `EnableTOTPRequest`
- `TOTPEnrollmentResponse`
- `VerifyTOTPEnrollmentRequest`
- `EnableSMSMFARequest`
- `VerifyMFARequest`

### Teams
- `CreateTeamRequest`
- `UpdateTeamRequest`
- `InviteTeamMemberRequest`

### Permissions
- `PermissionGrantRequest`
- `PermissionCheckResult`

## Enums

All enums use String raw values for JSON compatibility:

```swift
enum OAuthProviderType: String, Codable {
    case google
    case github
    case facebook
    case microsoft
    case apple
    // ... and more
}

enum SubscriptionStatus: String, Codable {
    case active
    case trialing
    case pastDue = "past_due"
    case canceled
    // ... and more
}
```

## File Structure

```
Models/
├── Models.swift                  # Index file
├── User/
│   └── BaseUser.swift           # User, OAuthConnection, TeamMembership (3 types)
├── ContactChannel/
│   └── ContactChannel.swift     # ContactChannel, ContactChannelType (2 types)
├── Project/
│   └── Project.swift            # Project and 14 config types (15 types)
├── Permission/
│   └── Permission.swift         # Permission, PermissionDefinition, Role, etc. (5 types)
├── Team/
│   └── Team.swift               # Team, TeamMember, Invitation, etc. (8 types)
├── Auth/
│   ├── AuthSession.swift        # Session and auth request types (16 types)
│   └── MFA.swift                # MFA configuration and requests (12 types)
└── Payments/
    └── Payment.swift            # Subscription, Invoice, Payment methods (13 types)
```

## Dependencies

- `Foundation` framework (Date, Codable, etc.)
- `AnyCodable` from `StackAuth/Networking/Errors.swift`

## Notes

- All types are marked `public` for external access
- Properties use Swift naming conventions (camelCase)
- JSON keys are automatically converted from snake_case
- Date properties decode from ISO8601 strings
- Deprecated properties are marked with `@available(*, deprecated)`
- Models are immutable (using `let` properties)
- Thread-safe value types (struct)
