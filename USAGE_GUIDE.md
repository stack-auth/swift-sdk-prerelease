# Stack Auth Swift SDK - Usage Guide

This guide walks you through common use cases and patterns for the Stack Auth Swift SDK.

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Authentication](#authentication)
3. [User Management](#user-management)
4. [Team Management](#team-management)
5. [Permissions](#permissions)
6. [Payments & Billing](#payments--billing)
7. [OAuth Integration](#oauth-integration)
8. [Error Handling](#error-handling)
9. [Server-Side Operations](#server-side-operations)

## Installation & Setup

### Basic Setup

```swift
import StackAuth

// Initialize for client-side (iOS/macOS app)
let stack = StackClientApp(
    projectId: "your-project-id",
    publishableClientKey: "your-publishable-key",
    tokenStore: .memory
)

// Initialize for server-side (Swift backend)
let serverStack = StackServerApp(
    projectId: "your-project-id",
    publishableClientKey: "your-publishable-key",
    secretServerKey: "your-secret-key"
)
```

### Custom Configuration

```swift
let stack = StackClientApp(
    projectId: "your-project-id",
    publishableClientKey: "your-key",
    baseURL: "https://api.stack-auth.com", // Optional
    tokenStore: .memory,                    // .memory, .explicit(), or .none
    urls: StackClientURLs(                  // Optional custom URLs
        signIn: "/custom/signin",
        afterSignIn: "/dashboard"
    )
)
```

## Authentication

### Email/Password Sign Up

```swift
do {
    try await stack.signUpWithCredential(
        email: "user@example.com",
        password: "SecurePassword123!"
    )

    // User is now signed in
    let user = try await stack.getUser()
    print("Welcome, \(user?.displayName ?? "User")!")

} catch let error as StackAuthAPIError {
    switch error.code {
    case "user_email_already_exists":
        print("This email is already registered")
    case "password_requirements_not_met":
        print("Password is too weak")
    default:
        print("Error: \(error.message)")
    }
}
```

### Email/Password Sign In

```swift
do {
    try await stack.signInWithCredential(
        email: "user@example.com",
        password: "password"
    )

    // Successfully signed in
    let user = try await stack.getUser()

} catch let error as StackAuthAPIError where error.code == "multi_factor_authentication_required" {
    // User has MFA enabled
    let attemptCode = error.details?["attempt_code"]?.value as? String

    // Show MFA input UI
    let otpCode = await showMFAInput()

    // Complete sign-in with MFA
    try await stack.signInWithMfa(
        otp: otpCode,
        attemptCode: attemptCode!
    )
}
```

### Magic Link Authentication

```swift
// Step 1: Send magic link
let result = try await stack.sendMagicLinkEmail(
    email: "user@example.com",
    callbackUrl: "https://yourapp.com/auth/magic-link"
)

print("Magic link sent! Nonce: \(result.nonce)")

// Step 2: When user clicks link, extract code from URL
let code = extractCodeFromURL(url)

// Step 3: Complete sign-in
try await stack.signInWithMagicLink(code: code)
```

### Check Authentication Status

```swift
// Option 1: Return null if not authenticated
let user = try await stack.getUser(or: .returnNull)
if let user = user {
    print("User is signed in: \(user.displayName ?? "")")
} else {
    print("Not signed in")
}

// Option 2: Throw error if not authenticated
do {
    let user = try await stack.getUser(or: .throw)
    // User is definitely authenticated here
} catch {
    // Not authenticated
}

// Option 3: Create anonymous user if not authenticated
let user = try await stack.getUser(or: .anonymous)
// Always returns a user (anonymous if not signed in)

// Option 4: Redirect to sign-in (browser only)
// let user = try await stack.getUser(or: .redirect)
```

### Sign Out

```swift
try await stack.signOut()
// User is now signed out, tokens cleared
```

## User Management

### Get Current User

```swift
guard let user = try await stack.getUser() else {
    print("Not signed in")
    return
}

print("ID: \(user.id)")
print("Email: \(user.primaryEmail ?? "none")")
print("Display Name: \(user.displayName ?? "none")")
print("Verified: \(user.primaryEmailVerified)")
print("Has Password: \(user.hasPassword)")
print("MFA Enabled: \(user.otpAuthEnabled)")
```

### Update User Profile

```swift
let user = try await stack.getUser()!

// Update multiple fields
try await user.update(.init(
    displayName: "John Doe",
    profileImageUrl: "https://example.com/avatar.jpg",
    clientMetadata: [
        "preferences": AnyCodable(["theme": "dark"]),
        "notifications": AnyCodable(true)
    ]
))

// Or use convenience methods
try await user.setDisplayName("Jane Doe")
```

### Password Management

```swift
let user = try await stack.getUser()!

// Change password
try await user.updatePassword(.init(
    oldPassword: "current_password",
    newPassword: "new_password"
))

// Set password (for users who signed up via OAuth)
if !user.hasPassword {
    try await user.setPassword(.init(
        password: "new_password"
    ))
}
```

### Password Reset Flow

```swift
// Step 1: User requests password reset
try await stack.sendForgotPasswordEmail(
    email: "user@example.com",
    callbackUrl: "https://yourapp.com/reset-password"
)

// Step 2: Verify reset code before showing form
let code = extractCodeFromURL(url)
try await stack.verifyPasswordResetCode(code: code)

// Step 3: Reset password
try await stack.resetPassword(
    code: code,
    password: "new_secure_password"
)
```

### Email Verification

```swift
// Send verification email
let channel = try await user.listContactChannels().first!
try await channel.sendVerificationEmail(
    callbackUrl: "https://yourapp.com/verify"
)

// Verify email with code from link
let code = extractCodeFromURL(url)
try await stack.verifyEmail(code: code)
```

### Contact Channels

```swift
// List all contact channels
let channels = try await user.listContactChannels()
for channel in channels {
    print("\(channel.type): \(channel.value)")
    print("  Primary: \(channel.isPrimary)")
    print("  Verified: \(channel.isVerified)")
    print("  Used for auth: \(channel.usedForAuth)")
}

// Add new email
let newChannel = try await user.createContactChannel(.init(
    type: "email",
    value: "secondary@example.com",
    usedForAuth: true,
    isPrimary: false
))

// Update contact channel
try await newChannel.update(.init(
    isPrimary: true,
    usedForAuth: true
))

// Delete contact channel
try await newChannel.delete()
```

## Team Management

### Create Team

```swift
let user = try await stack.getUser()!

let team = try await user.createTeam(.init(
    displayName: "Acme Corp",
    profileImageUrl: "https://example.com/logo.png"
))

// Team is automatically selected
print("Created team: \(team.displayName)")
```

### List Teams

```swift
let teams = try await user.listTeams()
for team in teams {
    print("\(team.displayName) - \(team.id)")
}
```

### Switch Team

```swift
// Set selected team
try await user.setSelectedTeam(team)

// Or by ID
try await user.setSelectedTeam("team-id")

// Unselect team
try await user.setSelectedTeam(nil)
```

### Invite Team Members

```swift
let team = try await user.getTeam("team-id")!

// Send invitation
try await team.inviteUser(
    email: "member@example.com",
    callbackUrl: "https://yourapp.com/accept-invite"
)

// List pending invitations
let invitations = try await team.listInvitations()
for invite in invitations {
    print("Invited: \(invite.recipientEmail ?? "unknown")")
    print("Expires: \(invite.expiresAt)")
}

// Revoke invitation
try await invitations[0].revoke()
```

### Accept Team Invitation

```swift
// Extract code from invitation email
let code = extractCodeFromURL(url)

// Verify invitation is valid
try await stack.verifyTeamInvitationCode(code: code)

// Get invitation details
let details = try await stack.getTeamInvitationDetails(code: code)
print("Joining team: \(details.teamDisplayName)")

// Accept invitation
try await stack.acceptTeamInvitation(code: code)
```

### List Team Members

```swift
let members = try await team.listUsers()
for member in members {
    print("Member: \(member.displayName ?? "Unknown")")
    print("  Profile: \(member.teamProfile.displayName ?? "")")
}
```

### Leave Team

```swift
try await user.leaveTeam(team)
```

## Permissions

### Check Permissions

```swift
// Check project-level permission
let canManageUsers = try await user.hasPermission(
    permissionId: "manage_users"
)

// Check team-level permission
let canEditTeam = try await user.hasPermission(
    scope: team,
    permissionId: "edit"
)
```

### List Permissions

```swift
// List project permissions
let projectPerms = try await user.listPermissions()

// List team permissions (including inherited)
let teamPerms = try await user.listPermissions(
    scope: team,
    recursive: true
)

for perm in teamPerms {
    print("Permission: \(perm.id)")
}
```

### Grant/Revoke Permissions (Server-Side)

```swift
let serverApp = StackServerApp(...)
let user = try await serverApp.getUser(userId)!

// Grant permission
try await user.grantPermission(
    scope: team,
    permissionId: "admin"
)

// Revoke permission
try await user.revokePermission(
    scope: team,
    permissionId: "admin"
)
```

## Payments & Billing

### Check Item Quantity (Credits/Features)

```swift
// Get item (e.g., API credits)
let credits = try await user.getItem(itemId: "api-credits")
print("Credits available: \(credits.nonNegativeQuantity)")
print("Actual balance: \(credits.quantity)") // May be negative

// Check if feature is enabled
let hasPremium = try await user.hasItem(itemId: "premium-feature")
if hasPremium {
    print("Premium features enabled")
}
```

### List Available Products

```swift
let productsList = try await user.listProducts()
for product in productsList.products {
    print("\(product.displayName)")
    print("  Type: \(product.type)")
    print("  Stackable: \(product.stackable)")

    if let subscription = product.subscription {
        print("  Period ends: \(subscription.currentPeriodEnd ?? Date())")
        print("  Will cancel: \(subscription.cancelAtPeriodEnd)")
    }
}

// Load more with cursor
if let nextCursor = productsList.nextCursor {
    let moreProducts = try await user.listProducts(cursor: nextCursor)
}
```

### Create Checkout

```swift
let checkoutUrl = try await user.createCheckoutUrl(
    productId: "premium-plan",
    returnUrl: "https://yourapp.com/success"
)

// Open checkout in browser
openURL(checkoutUrl)
```

### Get Billing Info

```swift
let billing = try await user.getBilling()

if billing.hasCustomer {
    if let card = billing.defaultPaymentMethod {
        print("Card: \(card.brand ?? "unknown") ending in \(card.last4 ?? "")")
        print("Expires: \(card.expMonth ?? 0)/\(card.expYear ?? 0)")
    }
} else {
    print("No payment method on file")
}
```

### Cancel Subscription

```swift
try await stack.cancelSubscription(
    productId: "premium-plan",
    teamId: team.id // Optional, for team subscriptions
)
```

### Server-Side: Grant Products

```swift
let serverApp = StackServerApp(...)

// Grant product to user
try await serverApp.grantProduct(
    userId: user.id,
    productId: "premium-plan",
    quantity: 1
)

// Grant inline product
try await serverApp.grantProduct(
    userId: user.id,
    product: InlineProduct(
        displayName: "Special Credits",
        type: "one_time",
        prices: [InlinePrice(amount: 1000, currency: "usd")]
    ),
    quantity: 100
)
```

### Server-Side: Manage Items

```swift
// Get server item
let item = try await serverApp.getItem(
    userId: user.id,
    itemId: "api-credits"
) as! ServerItem

// Increase quantity
try await item.increaseQuantity(100)

// Decrease quantity (can go negative)
try await item.decreaseQuantity(50)

// Try to decrease (atomic, prevents overdraft)
let success = try await item.tryDecreaseQuantity(10)
if success {
    print("Credits deducted")
} else {
    print("Insufficient credits")
}
```

## OAuth Integration

### List Connected Providers

```swift
let providers = try await user.listOAuthProviders()
for provider in providers {
    print("\(provider.type): \(provider.email ?? "")")
    print("  Can sign in: \(provider.allowSignIn)")
    print("  Can connect: \(provider.allowConnectedAccounts)")
}
```

### Get Connected Account for API Access

```swift
// Get connection to call third-party API
let connection = try await user.getConnectedAccount(
    providerId: "google",
    scopes: [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/gmail.readonly"
    ],
    or: .returnNull
)

if let connection = connection {
    // Get access token for API calls
    let accessToken = try await connection.getAccessToken()

    // Use token to call Google Calendar API
    let events = try await fetchGoogleCalendarEvents(token: accessToken)
} else {
    // Not connected - prompt user to connect
    print("Please connect your Google account")
}
```

### Update OAuth Provider Settings

```swift
let provider = try await user.getOAuthProvider("provider-id")!

let result = await provider.update(.init(
    allowSignIn: true,
    allowConnectedAccounts: true
))

switch result {
case .success:
    print("Provider updated")
case .failure(let error):
    print("Error: \(error.message)")
}
```

## Error Handling

### Structured Error Handling

```swift
do {
    try await stack.signInWithCredential(email: email, password: password)

} catch let error as StackAuthAPIError {
    // Handle known Stack Auth errors
    switch error.code {
    case "email_password_mismatch":
        showError("Invalid email or password")

    case "multi_factor_authentication_required":
        let attemptCode = error.details?["attempt_code"]?.value as? String
        showMFAPrompt(attemptCode: attemptCode!)

    case "user_email_already_exists":
        showError("This email is already registered")

    case "password_requirements_not_met":
        showError("Password must be at least 8 characters")

    default:
        showError(error.message)
    }

} catch {
    // Handle unexpected errors
    showError("An unexpected error occurred: \(error)")
}
```

### Result Types

```swift
// Some methods return Result for expected failures
let result = await provider.update(.init(allowSignIn: true))

switch result {
case .success:
    print("Updated successfully")

case .failure(let error):
    if error.code == "oauth_provider_account_id_already_used_for_sign_in" {
        print("This account is already linked to another user")
    } else {
        print("Error: \(error.message)")
    }
}
```

## Server-Side Operations

### List All Users

```swift
let serverApp = StackServerApp(...)

// List users with pagination
let users = try await serverApp.listUsers(
    limit: 50,
    orderBy: "signedUpAt",
    desc: true
)

for user in users {
    print("\(user.displayName ?? "Unknown") - \(user.primaryEmail ?? "")")
}

// Load more
if let nextCursor = users.nextCursor {
    let moreUsers = try await serverApp.listUsers(cursor: nextCursor)
}
```

### Create User

```swift
let newUser = try await serverApp.createUser(
    primaryEmail: "newuser@example.com",
    displayName: "New User",
    primaryEmailVerified: true,
    password: "initial_password",
    clientMetadata: ["source": AnyCodable("admin_import")]
)

print("Created user: \(newUser.id)")
```

### Update User Server-Side

```swift
let user = try await serverApp.getUser(userId)!

try await user.updateServer(.init(
    displayName: "Updated Name",
    primaryEmailVerified: true,
    serverMetadata: [
        "internal_notes": AnyCodable("VIP customer"),
        "account_tier": AnyCodable(3)
    ]
))
```

### Impersonate User

```swift
// Create impersonation session
let session = try await user.createSession(.init(
    expiresInMillis: 3600000, // 1 hour
    isImpersonation: true
))

let tokens = session.getTokens()
print("Access token: \(tokens.accessToken)")
print("Refresh token: \(tokens.refreshToken)")

// Use these tokens to act as the user
```

### Send Email

```swift
try await serverApp.sendEmail(
    to: "user@example.com",
    subject: "Welcome!",
    html: "<h1>Welcome to our app!</h1><p>Get started by...</p>",
    text: "Welcome to our app! Get started by..."
)
```

### Email Delivery Stats

```swift
let stats = try await serverApp.getEmailDeliveryStats()
print("Delivered: \(stats.delivered)")
print("Bounced: \(stats.bounced)")
print("Complained: \(stats.complained)")
print("Total: \(stats.total)")
```

### Team Administration

```swift
// Create team server-side
let team = try await serverApp.createTeam(
    displayName: "Enterprise Account",
    profileImageUrl: "https://example.com/logo.png",
    creatorUserId: userId
)

// Directly add user (no invitation needed)
try await team.addUser(userId: "user-id")

// Remove user
try await team.removeUser(userId: "user-id")
```

## Best Practices

1. **Always handle errors appropriately**
   ```swift
   do {
       try await operation()
   } catch let error as StackAuthAPIError {
       // Handle known errors
   } catch {
       // Handle unexpected errors
   }
   ```

2. **Use weak references for app in custom wrappers**
   ```swift
   class MyUserManager {
       weak var app: StackClientApp? // Prevents retain cycles
   }
   ```

3. **Check authentication before operations**
   ```swift
   guard let user = try await stack.getUser(or: .returnNull) else {
       // Handle unauthenticated state
       return
   }
   ```

4. **Use convenience methods when available**
   ```swift
   // Good
   try await user.setDisplayName("John")

   // Also fine, but more verbose
   try await user.update(.init(displayName: "John"))
   ```

5. **Store tokens securely (iOS/macOS)**
   ```swift
   // Implement custom token store using Keychain
   class KeychainTokenStore: TokenStore {
       // Store in iOS Keychain for security
   }
   ```

For more examples, see `Sources/StackAuthExample/main.swift` in the repository.
