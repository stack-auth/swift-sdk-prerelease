# Team Models Quick Reference

## At a Glance

| Feature | Team | ClientTeam | ServerTeam |
|---------|------|------------|------------|
| **Purpose** | Base data model | Client-side operations | Server-side operations |
| **Type** | Class | Class (extends Team) | Class (extends ClientTeam) |
| **App Reference** | None | `weak var app: StackClientApp?` | `weak var serverApp: StackServerApp?` |
| **Authentication** | N/A | User access token | Server API key |
| **Metadata Access** | Read-only | Client metadata only | Both client & server metadata |

## Method Comparison

### Team Management

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| Update team | ❌ | ✅ `update()` (client metadata) | ✅ `updateServer()` (includes server metadata) |
| Delete team | ❌ | ✅ `delete()` | ✅ (inherited) |

### User Management

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| List users | ❌ | ✅ `listUsers()` | ✅ `listUsersServer()` (with pagination) |
| Invite user | ❌ | ✅ `inviteUser()` | ✅ `createInvitation()` (with metadata) |
| Add user directly | ❌ | ❌ | ✅ `addUser()` |
| Remove user | ❌ | Via TeamUser | ✅ `removeUser()` |
| Update role | ❌ | Via TeamUser | ✅ `updateUserRole()` |
| Get specific user | ❌ | Filter listUsers() | ✅ `getUser()` |

### Invitation Management

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| List invitations | ❌ | ✅ `listInvitations()` | ✅ (inherited) |
| Create invitation | ❌ | ✅ `inviteUser()` | ✅ `createInvitation()` (with metadata) |
| Revoke invitation | ❌ | ❌ | ✅ `revokeInvitation()` |
| Accept invitation | ❌ | ❌ | ✅ `acceptInvitation()` |

### API Key Management

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| Create API key | ❌ | ✅ `createApiKey()` | ✅ (inherited) |
| List API keys | ❌ | ✅ `listApiKeys()` | ✅ (inherited) |
| Revoke API key | ❌ | ❌ | ✅ `revokeApiKey()` |
| Update API key | ❌ | ❌ | ✅ `updateApiKey()` |

### Permissions

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| Grant permission | ❌ | ❌ | ✅ `grantPermission()` |
| Revoke permission | ❌ | ❌ | ✅ `revokePermission()` |
| List permissions | ❌ | ❌ | ✅ `listUserPermissions()` |

### Billing (Customer Protocol)

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| Create checkout URL | ❌ | ✅ | ✅ (inherited) |
| Get billing info | ❌ | ✅ | ✅ (inherited) |
| Get item | ❌ | ✅ (returns Item) | ✅ `getServerItem()` (returns ServerItem) |
| List items | ❌ | ✅ (returns [Item]) | ✅ `listServerItems()` (returns [ServerItem]) |
| Grant/revoke items | ❌ | ❌ | ✅ `grantItem()`, `revokeItem()` |
| Has item | ❌ | ✅ | ✅ (inherited) |
| Get item quantity | ❌ | ✅ | ✅ (inherited) |
| List products | ❌ | ✅ | ✅ (inherited) |

### Analytics

| Method | Team | ClientTeam | ServerTeam |
|--------|------|------------|------------|
| Get statistics | ❌ | ❌ | ✅ `getStats()` |
| Get activity logs | ❌ | ❌ | ✅ `getActivity()` |

## When to Use Each Class

### Use `Team` when:
- Displaying team information
- Passing team data between components
- Serializing/deserializing team data
- No operations needed, just data

```swift
struct TeamCard: View {
    let team: Team

    var body: some View {
        VStack {
            Text(team.displayName)
            Text("\(team.members.count) members")
        }
    }
}
```

### Use `ClientTeam` when:
- Building a client application (iOS, macOS, web)
- User needs to manage their team
- User-initiated operations (invite, update, etc.)
- Billing and subscription management
- User authentication via access token

```swift
// In a client app
class TeamViewModel {
    let team: ClientTeam

    func inviteMember(email: String) async throws {
        try await team.inviteUser(.init(
            email: email,
            role: "member"
        ))
    }
}
```

### Use `ServerTeam` when:
- Building a server/backend application
- Administrative operations
- Batch operations on teams
- Server-to-server communication
- Need to modify server metadata
- Analytics and reporting
- Direct user management (bypassing invitations)

```swift
// In a server/backend
class TeamService {
    func setupNewTeam(teamId: String, ownerId: String) async throws {
        let team: ServerTeam = try await serverApp.getTeam(teamId)

        // Set server metadata
        try await team.updateServer(.init(
            serverMetadata: [
                "plan": AnyCodable("premium"),
                "setupDate": AnyCodable(Date())
            ]
        ))

        // Grant initial credits
        try await team.grantItem(itemId: "credits", quantity: 1000)

        // Set up admin permissions
        try await team.grantPermission(ownerId, permission: "admin:all")
    }
}
```

## Type Relationships

```
┌──────────────────────────────────────┐
│            Team (Base)               │
│  - All properties                    │
│  - Codable, Identifiable             │
│  - No app reference                  │
└──────────────────────────────────────┘
                  ▲
                  │ extends
                  │
┌──────────────────────────────────────┐
│           ClientTeam                 │
│  + weak var app: StackClientApp?     │
│  + update()                          │
│  + delete()                          │
│  + inviteUser()                      │
│  + listUsers()                       │
│  + createApiKey()                    │
│  + Customer protocol methods         │
└──────────────────────────────────────┘
                  ▲
                  │ extends
                  │
┌──────────────────────────────────────┐
│          ServerTeam                  │
│  + weak var serverApp: StackServerApp│
│  + updateServer()                    │
│  + addUser()                         │
│  + removeUser()                      │
│  + grantPermission()                 │
│  + grantItem()                       │
│  + getStats()                        │
│  + getActivity()                     │
└──────────────────────────────────────┘
```

## Key Properties Access

| Property | Team | ClientTeam | ServerTeam |
|----------|------|------------|------------|
| id | ✅ Read | ✅ Read | ✅ Read |
| displayName | ✅ Read | ✅ Read/Write* | ✅ Read/Write* |
| description | ✅ Read | ✅ Read/Write* | ✅ Read/Write* |
| profileImageUrl | ✅ Read | ✅ Read/Write* | ✅ Read/Write* |
| clientMetadata | ✅ Read | ✅ Read/Write* | ✅ Read/Write* |
| serverMetadata | ✅ Read | ❌ Write | ✅ Read/Write* |
| settings | ✅ Read | ✅ Read/Write* | ✅ Read/Write* |
| members | ✅ Read | ✅ Read | ✅ Read |
| invitations | ✅ Read | ✅ Read | ✅ Read |

\* Via update methods (update() or updateServer())

## Common Patterns

### Converting Between Types

```swift
// Team -> ClientTeam
let clientTeam = ClientTeam(from: team, app: app)

// Team -> ServerTeam
let serverTeam = ServerTeam(from: team, app: serverApp)

// ClientTeam -> ServerTeam (upcast)
let serverTeam = team as? ServerTeam
```

### Caching Strategy

```swift
// Client app
class TeamCache {
    private var teams: [String: ClientTeam] = [:]

    func getTeam(_ id: String, app: StackClientApp) async throws -> ClientTeam {
        if let cached = teams[id] {
            return cached
        }

        let team: Team = try await app.apiClient.request(...)
        let clientTeam = ClientTeam(from: team, app: app)
        teams[id] = clientTeam
        return clientTeam
    }
}
```

### Error Handling Pattern

```swift
// Recommended pattern for all team operations
do {
    try await team.update(.init(displayName: "New Name"))
    print("✅ Team updated successfully")
} catch let error as StackAuthAPIError {
    print("❌ API Error: \(error.message) (code: \(error.code))")
} catch {
    print("❌ Unexpected error: \(error.localizedDescription)")
}
```

## API Endpoint Mapping

| Method | Endpoint | Access Level |
|--------|----------|--------------|
| `update()` | `PATCH /teams/{id}` | User token |
| `updateServer()` | `PATCH /teams/{id}` | Server only |
| `delete()` | `DELETE /teams/{id}` | User token |
| `inviteUser()` | `POST /teams/{id}/invitations` | User token |
| `listUsers()` | `GET /teams/{id}/users` | User token |
| `addUser()` | `POST /teams/{id}/users` | Server only |
| `grantPermission()` | `POST /teams/{id}/users/{userId}/permissions` | Server only |
| `getStats()` | `GET /teams/{id}/stats` | Server only |
| `createCheckoutUrl()` | `POST /customers/team/{id}/checkout` | User token |
| `grantItem()` | `POST /customers/team/{id}/items/{itemId}/grant` | Server only |
