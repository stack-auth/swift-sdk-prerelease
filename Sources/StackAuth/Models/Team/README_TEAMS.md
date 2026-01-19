# Team Models

This directory contains the complete team management implementation for Stack Auth SDK.

## File Structure

- **Team.swift**: Base Team class with all core team properties
- **ClientTeam.swift**: Client-side Team class with methods for team interactions (requires user authentication)
- **ServerTeam.swift**: Server-side Team class with additional server-only capabilities

## Class Hierarchy

```
Team (base class)
  └── ClientTeam (client-side methods)
        └── ServerTeam (server-side methods)
```

## Team.swift

The base `Team` class contains all team properties:

- `id`: Unique team identifier
- `displayName`: Team name
- `description`: Optional team description
- `profileImageUrl`: Optional team avatar
- `createdAt`, `updatedAt`: Timestamps
- `createdBy`: Creator user ID
- `clientMetadata`: Client-accessible metadata
- `serverMetadata`: Server-only metadata
- `members`: List of team members
- `invitations`: Pending invitations
- `settings`: Team configuration

### Supporting Types

- **TeamMember**: Represents a member of the team
- **TeamInvitation**: Represents a pending team invitation
- **TeamSettings**: Team configuration options
- **CreateTeamRequest**: Request structure for creating teams
- **UpdateTeamRequest**: Request structure for updating teams
- **InviteTeamMemberRequest**: Request structure for inviting members

## ClientTeam.swift

The `ClientTeam` class extends `Team` with client-side methods:

### Properties

- `weak var app: StackClientApp?`: Reference to the client app for API calls

### Methods

#### Team Management
- `update(_ options: UpdateOptions)`: Update team properties
- `delete()`: Delete the team

#### User Management
- `inviteUser(_ request: InviteTeamMemberRequest)`: Invite a user to the team
- `listUsers()`: Get all team members
- `listInvitations()`: Get pending invitations

#### API Key Management
- `createApiKey(_ request: CreateApiKeyRequest)`: Create a new API key
- `listApiKeys()`: List all API keys

#### Customer Protocol (Billing)
- `createCheckoutUrl(productId:returnUrl:)`: Create a checkout URL for a product
- `getBilling()`: Get billing information
- `getItem(itemId:)`: Get a specific item
- `listItems()`: List all items
- `hasItem(itemId:)`: Check if team has an item
- `getItemQuantity(itemId:)`: Get quantity of an item
- `listProducts(cursor:limit:)`: List available products

### Additional Types

- **TeamUser**: User in team context with team-specific methods
  - `updateRole(_:)`: Update user's role
  - `remove()`: Remove user from team

- **ApiKey**: API key model
  - `id`, `key`, `description`
  - `createdAt`, `expiresAt`, `lastUsedAt`
  - `permissions`, `isActive`
  - `isValid`: Computed property

- **CreateApiKeyRequest**: Request for creating API keys
- **TeamPermission**: Permission in team context

## ServerTeam.swift

The `ServerTeam` class extends `ClientTeam` with server-only methods:

### Properties

- `weak var serverApp: StackServerApp?`: Reference to the server app

### Server-Only Methods

#### Team Management
- `updateServer(_ options: ServerUpdateOptions)`: Update team with server metadata

#### User Management
- `addUser(_ userId:role:)`: Add a user to the team
- `removeUser(_ userId:)`: Remove a user from the team
- `updateUserRole(_ userId:role:)`: Update user's role
- `getUser(_ userId:)`: Get a specific user
- `listUsersServer(cursor:limit:)`: List users with pagination

#### Invitation Management
- `createInvitation(_ request: ServerInviteTeamMemberRequest)`: Create invitation with metadata
- `revokeInvitation(_ invitationId:)`: Revoke an invitation
- `acceptInvitation(_ invitationId:userId:)`: Accept invitation on behalf of user

#### API Key Management
- `revokeApiKey(_ apiKeyId:)`: Revoke an API key
- `updateApiKey(_ apiKeyId:description:isActive:)`: Update API key

#### Permission Management
- `grantPermission(_ userId:permission:)`: Grant permission to user
- `revokePermission(_ userId:permission:)`: Revoke permission from user
- `listUserPermissions(_ userId:)`: List user's permissions

#### Analytics and Stats
- `getStats()`: Get team statistics
- `getActivity(from:to:limit:)`: Get team activity logs

#### Item Management (Server-Only)
- `getServerItem(itemId:)`: Get ServerItem with modification methods
- `listServerItems()`: List ServerItems
- `grantItem(itemId:quantity:)`: Grant items to team
- `revokeItem(itemId:quantity:)`: Revoke items from team

### Additional Types

- **ServerTeamUser**: Extended TeamUser with server capabilities
  - `updateRoleServer(_:)`: Update role (server-side)
  - `removeServer()`: Remove user (server-side)
  - `grantPermission(_:)`: Grant permission
  - `revokePermission(_:)`: Revoke permission

- **ServerInviteTeamMemberRequest**: Extended invitation request with metadata
- **TeamStats**: Team statistics (member count, invitations, API keys, activity)
- **TeamActivity**: Activity log entry
- **ServerTeamUsersList**: Paginated user list

## Protocols

### StackClientApp

Required for ClientTeam to make API calls:

```swift
public protocol StackClientApp: AnyObject {
    var apiClient: APIClient { get }
    var tokenStore: TokenStore { get }
}
```

### StackServerApp

Required for ServerTeam (extends StackClientApp):

```swift
public protocol StackServerApp: StackClientApp {
    // Server-specific properties or methods
}
```

### Customer

Teams implement the Customer protocol for billing:

```swift
public protocol Customer: AnyObject {
    var id: String { get }
    func createCheckoutUrl(productId: String, returnUrl: String?) async throws -> String
    func getBilling() async throws -> CustomerBilling
    func getItem(itemId: String) async throws -> Item
    func listItems() async throws -> [Item]
    func hasItem(itemId: String) async throws -> Bool
    func getItemQuantity(itemId: String) async throws -> Int
    func listProducts(cursor: String?, limit: Int?) async throws -> CustomerProductsList
}
```

## Usage Examples

### Client-Side Usage

```swift
// Get current user's team
let team: ClientTeam = try await user.getTeam(teamId)

// Update team
try await team.update(.init(displayName: "New Name"))

// Invite user
let invitation = try await team.inviteUser(.init(
    email: "user@example.com",
    role: "member"
))

// List team members
let users = try await team.listUsers()

// Create API key
let apiKey = try await team.createApiKey(.init(
    description: "Production API Key",
    permissions: ["read:data"]
))

// Billing
let checkoutUrl = try await team.createCheckoutUrl(
    productId: "prod_123",
    returnUrl: "https://example.com/success"
)

let billing = try await team.getBilling()
let hasItem = try await team.hasItem(itemId: "item_123")
```

### Server-Side Usage

```swift
// Get team (server-side)
let team: ServerTeam = try await serverApp.getTeam(teamId)

// Update with server metadata
try await team.updateServer(.init(
    displayName: "New Name",
    serverMetadata: ["internalId": AnyCodable("abc123")]
))

// Add user directly
try await team.addUser("user_123", role: "admin")

// Grant permission
try await team.grantPermission("user_123", permission: "manage:team")

// Get statistics
let stats = try await team.getStats()
print("Members: \(stats.memberCount)")
print("Pending invitations: \(stats.pendingInvitationCount)")

// Get activity
let activities = try await team.getActivity(
    from: Date().addingTimeInterval(-86400 * 30), // Last 30 days
    limit: 50
)

// Grant items
try await team.grantItem(itemId: "credits", quantity: 100)
let serverItem = try await team.getServerItem(itemId: "credits")
try await serverItem.increaseQuantity(50)
```

## Access Token Handling

All methods that make API calls automatically handle access tokens:

1. Client methods use `app.tokenStore.getAccessToken()` for user authentication
2. Server methods use `isServerOnly: true` flag for server-to-server calls
3. The APIClient handles token inclusion in requests

## Error Handling

Methods throw errors in these cases:

- Missing app reference: `NSError` with "No app reference" message
- API errors: `StackAuthAPIError` with code and message
- Network errors: Standard URLSession errors

Always use try-await pattern:

```swift
do {
    try await team.update(.init(displayName: "New Name"))
} catch let error as StackAuthAPIError {
    print("API Error: \(error.message)")
} catch {
    print("Error: \(error)")
}
```

## Thread Safety

- All API methods are async and can be called from any thread
- Weak app references prevent retain cycles
- Mutable properties should be updated on the same actor/thread

## Performance Considerations

1. **Caching**: Team objects should be cached at the app level
2. **Pagination**: Use cursor-based pagination for large lists
3. **Weak References**: App references are weak to prevent memory leaks
4. **Lazy Loading**: Only fetch data when needed

## Integration with Other Models

- **CurrentUser**: Can create and manage teams
- **BaseUser**: Teams contain user references
- **Permission**: Teams integrate with permission system
- **Customer**: Teams implement Customer protocol for billing
- **Item/ServerItem**: Teams can have items for feature access
