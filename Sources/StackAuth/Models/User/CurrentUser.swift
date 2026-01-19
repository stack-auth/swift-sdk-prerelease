import Foundation

/// The authenticated user with methods to modify their own data
public class CurrentUser: BaseUser {
    weak var app: StackClientApp?

    public var selectedTeam: Team?

    public init(from baseUser: BaseUser, app: StackClientApp?, selectedTeam: Team? = nil) {
        self.app = app
        self.selectedTeam = selectedTeam
        super.init(
            id: baseUser.id,
            displayName: baseUser.displayName,
            primaryEmail: baseUser.primaryEmail,
            primaryEmailVerified: baseUser.primaryEmailVerified,
            profileImageUrl: baseUser.profileImageUrl,
            signedUpAt: baseUser.signedUpAt,
            clientMetadata: baseUser.clientMetadata,
            clientReadOnlyMetadata: baseUser.clientReadOnlyMetadata,
            hasPassword: baseUser.hasPassword,
            otpAuthEnabled: baseUser.otpAuthEnabled,
            passkeyAuthEnabled: baseUser.passkeyAuthEnabled,
            isMultiFactorRequired: baseUser.isMultiFactorRequired,
            isAnonymous: baseUser.isAnonymous,
            isRestricted: baseUser.isRestricted,
            restrictedReason: baseUser.restrictedReason
        )
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update Methods

    public struct UpdateOptions {
        public var displayName: String?
        public var clientMetadata: [String: AnyCodable]?
        public var selectedTeamId: String?
        public var profileImageUrl: String?
        public var otpAuthEnabled: Bool?
        public var passkeyAuthEnabled: Bool?
        public var primaryEmail: String?

        public init(
            displayName: String? = nil,
            clientMetadata: [String: AnyCodable]? = nil,
            selectedTeamId: String? = nil,
            profileImageUrl: String? = nil,
            otpAuthEnabled: Bool? = nil,
            passkeyAuthEnabled: Bool? = nil,
            primaryEmail: String? = nil
        ) {
            self.displayName = displayName
            self.clientMetadata = clientMetadata
            self.selectedTeamId = selectedTeamId
            self.profileImageUrl = profileImageUrl
            self.otpAuthEnabled = otpAuthEnabled
            self.passkeyAuthEnabled = passkeyAuthEnabled
            self.primaryEmail = primaryEmail
        }
    }

    public func update(_ options: UpdateOptions) async throws {
        guard let app = app else { return }

        var body: [String: Any] = [:]
        if let displayName = options.displayName {
            body["displayName"] = displayName
        }
        if let clientMetadata = options.clientMetadata {
            body["clientMetadata"] = clientMetadata
        }
        if let selectedTeamId = options.selectedTeamId {
            body["selectedTeamId"] = selectedTeamId
        }
        if let profileImageUrl = options.profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }
        if let otpAuthEnabled = options.otpAuthEnabled {
            body["otpAuthEnabled"] = otpAuthEnabled
        }
        if let passkeyAuthEnabled = options.passkeyAuthEnabled {
            body["passkeyAuthEnabled"] = passkeyAuthEnabled
        }
        if let primaryEmail = options.primaryEmail {
            body["primaryEmail"] = primaryEmail
        }

        let accessToken = await app.tokenStore.getAccessToken()
        let _: BaseUser = try await app.apiClient.request(
            path: "/users/me",
            method: "PATCH",
            body: body,
            accessToken: accessToken
        )

        // Update local properties
        if let displayName = options.displayName {
            self.displayName = displayName
        }
        if let clientMetadata = options.clientMetadata {
            self.clientMetadata = clientMetadata
        }
        if let profileImageUrl = options.profileImageUrl {
            self.profileImageUrl = profileImageUrl
        }
        if let otpAuthEnabled = options.otpAuthEnabled {
            self.otpAuthEnabled = otpAuthEnabled
        }
        if let passkeyAuthEnabled = options.passkeyAuthEnabled {
            self.passkeyAuthEnabled = passkeyAuthEnabled
        }
        if let primaryEmail = options.primaryEmail {
            self.primaryEmail = primaryEmail
        }
    }

    public func delete() async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/users/me",
            method: "DELETE",
            accessToken: accessToken
        )
        await app.tokenStore.clearTokens()
    }

    public func setDisplayName(_ displayName: String?) async throws {
        try await update(UpdateOptions(displayName: displayName))
    }

    public func setClientMetadata(_ metadata: [String: AnyCodable]) async throws {
        try await update(UpdateOptions(clientMetadata: metadata))
    }

    // MARK: - Password Methods

    public struct UpdatePasswordOptions {
        public let oldPassword: String
        public let newPassword: String

        public init(oldPassword: String, newPassword: String) {
            self.oldPassword = oldPassword
            self.newPassword = newPassword
        }
    }

    public func updatePassword(_ options: UpdatePasswordOptions) async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/users/me",
            method: "PATCH",
            body: ["oldPassword": options.oldPassword, "newPassword": options.newPassword],
            accessToken: accessToken
        )
    }

    public struct SetPasswordOptions {
        public let password: String

        public init(password: String) {
            self.password = password
        }
    }

    public func setPassword(_ options: SetPasswordOptions) async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/users/me/password",
            method: "POST",
            body: ["password": options.password],
            accessToken: accessToken
        )
        self.hasPassword = true
    }

    // MARK: - Team Methods

    public func listTeams() async throws -> [Team] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()
        let teams: [Team] = try await app.apiClient.request(
            path: "/users/me/teams",
            method: "GET",
            accessToken: accessToken
        )
        return teams.map { team in
            team.app = app
            return team
        }
    }

    public func getTeam(_ teamId: String) async throws -> Team? {
        let teams = try await listTeams()
        return teams.first { $0.id == teamId }
    }

    public struct CreateTeamOptions {
        public let displayName: String
        public let profileImageUrl: String?

        public init(displayName: String, profileImageUrl: String? = nil) {
            self.displayName = displayName
            self.profileImageUrl = profileImageUrl
        }
    }

    public func createTeam(_ options: CreateTeamOptions) async throws -> Team {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var body: [String: Any] = ["displayName": options.displayName, "creatorUserId": "me"]
        if let profileImageUrl = options.profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }

        let team: Team = try await app.apiClient.request(
            path: "/teams",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
        team.app = app

        // Select the new team
        try await update(UpdateOptions(selectedTeamId: team.id))
        self.selectedTeam = team

        return team
    }

    public func setSelectedTeam(_ teamOrId: Any?) async throws {
        let teamId: String?
        if let team = teamOrId as? Team {
            teamId = team.id
        } else if let id = teamOrId as? String {
            teamId = id
        } else {
            teamId = nil
        }

        try await update(UpdateOptions(selectedTeamId: teamId))
        if let teamId = teamId {
            self.selectedTeam = try await getTeam(teamId)
        } else {
            self.selectedTeam = nil
        }
    }

    public func leaveTeam(_ team: Team) async throws {
        guard let app = app else { return }
        let accessToken = await app.tokenStore.getAccessToken()
        try await app.apiClient.requestVoid(
            path: "/teams/\(team.id)/users/me",
            method: "DELETE",
            accessToken: accessToken
        )
    }

    // MARK: - Contact Channel Methods

    public func listContactChannels() async throws -> [ContactChannel] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()
        let channels: [ContactChannel] = try await app.apiClient.request(
            path: "/contact-channels",
            method: "GET",
            accessToken: accessToken
        )
        return channels.map { channel in
            channel.app = app
            return channel
        }
    }

    public struct CreateContactChannelOptions {
        public let type: String
        public let value: String
        public let usedForAuth: Bool
        public let isPrimary: Bool?

        public init(type: String = "email", value: String, usedForAuth: Bool, isPrimary: Bool? = nil) {
            self.type = type
            self.value = value
            self.usedForAuth = usedForAuth
            self.isPrimary = isPrimary
        }
    }

    public func createContactChannel(_ options: CreateContactChannelOptions) async throws -> ContactChannel {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var body: [String: Any] = [
            "type": options.type,
            "value": options.value,
            "usedForAuth": options.usedForAuth,
            "userId": "me"
        ]
        if let isPrimary = options.isPrimary {
            body["isPrimary"] = isPrimary
        }

        let channel: ContactChannel = try await app.apiClient.request(
            path: "/contact-channels",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
        channel.app = app
        return channel
    }

    // MARK: - OAuth Provider Methods

    public func listOAuthProviders() async throws -> [OAuthProvider] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()
        let providers: [OAuthProvider] = try await app.apiClient.request(
            path: "/users/me/oauth-providers",
            method: "GET",
            accessToken: accessToken
        )
        return providers.map { provider in
            provider.app = app
            return provider
        }
    }

    public func getOAuthProvider(_ id: String) async throws -> OAuthProvider? {
        let providers = try await listOAuthProviders()
        return providers.first { $0.id == id }
    }

    // MARK: - Permission Methods

    public func hasPermission(scope: Team? = nil, permissionId: String) async throws -> Bool {
        guard let app = app else { return false }
        let accessToken = await app.tokenStore.getAccessToken()
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "permissionId", value: permissionId)]
        if let teamId = scope?.id {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }

        struct HasPermissionResponse: Decodable {
            let hasPermission: Bool
        }

        let response: HasPermissionResponse = try await app.apiClient.request(
            path: "/users/me/permissions",
            method: "GET",
            queryItems: queryItems,
            accessToken: accessToken
        )
        return response.hasPermission
    }

    public func listPermissions(scope: Team? = nil, recursive: Bool? = nil) async throws -> [TeamPermission] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()
        var queryItems: [URLQueryItem] = []
        if let teamId = scope?.id {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }
        if let recursive = recursive {
            queryItems.append(URLQueryItem(name: "recursive", value: String(recursive)))
        }

        let permissions: [TeamPermission] = try await app.apiClient.request(
            path: "/users/me/permissions",
            method: "GET",
            queryItems: queryItems,
            accessToken: accessToken
        )
        return permissions
    }
}

// MARK: - Customer Protocol Implementation
extension CurrentUser: Customer {
    public func createCheckoutUrl(productId: String, returnUrl: String? = nil) async throws -> String {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var body: [String: Any] = ["productId": productId]
        if let returnUrl = returnUrl {
            body["returnUrl"] = returnUrl
        }

        struct CheckoutResponse: Decodable {
            let url: String
        }

        let response: CheckoutResponse = try await app.apiClient.request(
            path: "/customers/user/\(id)/checkout",
            method: "POST",
            body: body,
            accessToken: accessToken
        )
        return response.url
    }

    public func getBilling() async throws -> CustomerBilling {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        return try await app.apiClient.request(
            path: "/customers/user/\(id)/billing",
            method: "GET",
            accessToken: accessToken
        )
    }

    public func getItem(itemId: String) async throws -> Item {
        guard let app = app else {
            throw NSError(domain: "StackAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No app reference"])
        }
        let accessToken = await app.tokenStore.getAccessToken()
        return try await app.apiClient.request(
            path: "/customers/user/\(id)/items/\(itemId)",
            method: "GET",
            accessToken: accessToken
        )
    }

    public func listItems() async throws -> [Item] {
        guard let app = app else { return [] }
        let accessToken = await app.tokenStore.getAccessToken()
        return try await app.apiClient.request(
            path: "/customers/user/\(id)/items",
            method: "GET",
            accessToken: accessToken
        )
    }

    public func hasItem(itemId: String) async throws -> Bool {
        let item = try await getItem(itemId: itemId)
        return item.quantity > 0
    }

    public func getItemQuantity(itemId: String) async throws -> Int {
        let item = try await getItem(itemId: itemId)
        return item.quantity
    }

    public func listProducts(cursor: String? = nil, limit: Int? = nil) async throws -> CustomerProductsList {
        guard let app = app else {
            return CustomerProductsList(products: [], nextCursor: nil)
        }
        let accessToken = await app.tokenStore.getAccessToken()
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return try await app.apiClient.request(
            path: "/customers/user/\(id)/products",
            method: "GET",
            queryItems: queryItems,
            accessToken: accessToken
        )
    }
}
