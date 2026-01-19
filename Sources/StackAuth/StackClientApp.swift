import Foundation

/// Configuration URLs for Stack Auth client
public struct StackClientURLs {
    public let signIn: String?
    public let signUp: String?
    public let afterSignIn: String?
    public let afterSignUp: String?
    public let afterSignOut: String?
    public let emailVerification: String?
    public let passwordReset: String?
    public let magicLink: String?
    public let teamInvitation: String?

    public init(
        signIn: String? = nil,
        signUp: String? = nil,
        afterSignIn: String? = nil,
        afterSignUp: String? = nil,
        afterSignOut: String? = nil,
        emailVerification: String? = nil,
        passwordReset: String? = nil,
        magicLink: String? = nil,
        teamInvitation: String? = nil
    ) {
        self.signIn = signIn
        self.signUp = signUp
        self.afterSignIn = afterSignIn
        self.afterSignUp = afterSignUp
        self.afterSignOut = afterSignOut
        self.emailVerification = emailVerification
        self.passwordReset = passwordReset
        self.magicLink = magicLink
        self.teamInvitation = teamInvitation
    }
}

/// Options for getUser behavior when no user is signed in
public enum UserOrRedirect: String {
    case redirect = "redirect"
    case `throw` = "throw"
    case returnNull = "return-null"
    case anonymous = "anonymous"
}

/// Main client application class for Stack Auth
public class StackClientApp {
    public let projectId: String
    public let publishableClientKey: String
    public let baseURL: URL
    public let tokenStore: TokenStore
    public let urls: StackClientURLs
    public let apiClient: APIClient
    public let requestBuilder: RequestBuilder

    private var cachedProject: Project?
    private var projectFetchTask: Task<Project, Error>?

    /// Initialize a new Stack client application
    /// - Parameters:
    ///   - projectId: Your Stack Auth project ID
    ///   - publishableClientKey: Your publishable client key
    ///   - baseURL: Base URL for the Stack Auth API (defaults to https://api.stack-auth.com)
    ///   - tokenStoreType: Type of token storage to use
    ///   - urls: Configuration URLs for redirects
    ///   - extraHeaders: Additional headers to include in all requests
    public init(
        projectId: String,
        publishableClientKey: String,
        baseURL: URL = URL(string: "https://api.stack-auth.com")!,
        tokenStoreType: TokenStoreType = .memory,
        urls: StackClientURLs = StackClientURLs(),
        extraHeaders: [String: String] = [:]
    ) {
        self.projectId = projectId
        self.publishableClientKey = publishableClientKey
        self.baseURL = baseURL
        self.tokenStore = createTokenStore(type: tokenStoreType)
        self.urls = urls

        self.requestBuilder = RequestBuilder(
            baseURL: baseURL,
            projectId: projectId,
            publishableClientKey: publishableClientKey,
            secretServerKey: nil,
            extraHeaders: extraHeaders
        )

        self.apiClient = APIClient(requestBuilder: requestBuilder)
    }

    // MARK: - Authentication Methods

    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user, or throws if MFA is required
    public func signInWithCredential(email: String, password: String) async throws -> CurrentUser {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        // Response: { access_token, refresh_token, user_id }
        // Or MFA required error with attempt_code in details
        struct SignInResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let userId: String
        }

        let response: SignInResponse = try await apiClient.request(
            path: "/auth/password/sign-in",
            method: "POST",
            body: body
        )

        await tokenStore.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        
        // Fetch the full user object
        return try await getUser(or: .throw)!
    }

    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - verificationCallbackUrl: Optional URL for email verification link
    /// - Returns: The newly created user
    /// - Note: Display name and other profile fields must be set after sign-up via user.update()
    public func signUpWithCredential(
        email: String,
        password: String,
        verificationCallbackUrl: String? = nil
    ) async throws -> CurrentUser {
        // Per API spec: only email, password, and verification_callback_url allowed
        var body: [String: Any] = [
            "email": email,
            "password": password
        ]

        if let verificationCallbackUrl = verificationCallbackUrl {
            body["verificationCallbackUrl"] = verificationCallbackUrl
        }

        // Response: { access_token, refresh_token, user_id }
        struct SignUpResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let userId: String
        }

        let response: SignUpResponse = try await apiClient.request(
            path: "/auth/password/sign-up",
            method: "POST",
            body: body
        )

        await tokenStore.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        
        // Fetch the full user object
        return try await getUser(or: .throw)!
    }

    /// Send magic link / OTP email
    /// - Parameters:
    ///   - email: User's email address
    ///   - callbackUrl: URL for the magic link (required)
    /// - Returns: Nonce string for tracking (used with the 6-digit OTP code)
    /// - Note: The email contains both a magic link and a 6-digit OTP code.
    ///         User can either click the link or enter the code manually.
    public func sendMagicLinkEmail(email: String, callbackUrl: String) async throws -> String {
        let body: [String: Any] = [
            "email": email,
            "callbackUrl": callbackUrl
        ]

        struct OtpSendResponse: Decodable {
            let nonce: String
        }

        let response: OtpSendResponse = try await apiClient.request(
            path: "/auth/otp/send-sign-in-code",
            method: "POST",
            body: body
        )
        
        return response.nonce
    }

    /// Sign in with magic link / OTP code
    /// - Parameter code: The code from the magic link email
    /// - Returns: The authenticated user
    public func signInWithMagicLink(code: String) async throws -> CurrentUser {
        struct OtpSignInResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let userId: String
        }

        let response: OtpSignInResponse = try await apiClient.request(
            path: "/auth/otp/sign-in",
            method: "POST",
            body: ["code": code]
        )

        await tokenStore.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return try await getUser(or: .throw)!
    }

    /// Complete MFA authentication
    /// - Parameters:
    ///   - attemptCode: The attempt code from the MFA required error
    ///   - code: The TOTP code from the authenticator app
    /// - Returns: The authenticated user
    public func signInWithMfa(attemptCode: String, code: String) async throws -> CurrentUser {
        struct MfaResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let userId: String
        }

        let response: MfaResponse = try await apiClient.request(
            path: "/auth/mfa/sign-in",
            method: "POST",
            body: [
                "attemptCode": attemptCode,
                "otp": code
            ]
        )

        await tokenStore.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return try await getUser(or: .throw)!
    }

    /// Sign out the current user
    public func signOut() async {
        let accessToken = await tokenStore.getAccessToken()

        // Best effort to notify server (ignore errors, session may already be invalid)
        try? await apiClient.requestVoid(
            path: "/auth/sessions/current/sign-out",
            method: "POST",
            accessToken: accessToken
        )

        await tokenStore.clearTokens()
    }

    // MARK: - User Methods

    /// Get the current user
    /// - Parameter or: Behavior when no user is signed in
    /// - Returns: Current user or nil depending on `or` parameter
    public func getUser(or behavior: UserOrRedirect = .returnNull) async throws -> CurrentUser? {
        let accessToken = await tokenStore.getAccessToken()

        guard let accessToken = accessToken else {
            return try handleNoUser(behavior: behavior)
        }

        do {
            let user: BaseUser = try await withTokenRefresh {
                try await self.apiClient.request(
                    path: "/users/me",
                    method: "GET",
                    accessToken: accessToken
                )
            }
            return CurrentUser(from: user, app: self)
        } catch {
            // If we get an auth error, clear tokens and handle as no user
            if let apiError = error as? StackAuthAPIError, apiError.code == "user_not_signed_in" {
                await tokenStore.clearTokens()
                return try handleNoUser(behavior: behavior)
            }
            throw error
        }
    }

    /// Get partial user information (lightweight)
    public func getPartialUser() async -> BaseUser? {
        let accessToken = await tokenStore.getAccessToken()
        guard accessToken != nil else { return nil }

        return try? await withTokenRefresh {
            try await self.apiClient.request(
                path: "/users/me/partial",
                method: "GET",
                accessToken: accessToken
            )
        }
    }

    private func handleNoUser(behavior: UserOrRedirect) throws -> CurrentUser? {
        switch behavior {
        case .returnNull:
            return nil
        case .throw:
            throw StackAuthAPIError.userNotSignedIn()
        case .redirect:
            // In a mobile app, we can't really redirect, so return nil
            // Clients should handle this by showing sign-in UI
            return nil
        case .anonymous:
            // Create an anonymous user session
            // This would need backend support - for now return nil
            return nil
        }
    }

    // MARK: - Password Reset Methods

    /// Send forgot password email
    /// - Parameters:
    ///   - email: User's email address
    ///   - callbackUrl: Optional URL for the password reset link
    public func sendForgotPasswordEmail(email: String, callbackUrl: String? = nil) async throws {
        var body: [String: Any] = ["email": email]
        if let callbackUrl = callbackUrl {
            body["callbackUrl"] = callbackUrl
        }

        try await apiClient.requestVoid(
            path: "/auth/password/forgot",
            method: "POST",
            body: body
        )
    }

    /// Verify password reset code (check if it's valid before showing reset form)
    /// - Parameter code: The code from the password reset email
    /// - Throws: PasswordResetCodeInvalid if the code is invalid or expired
    public func verifyPasswordResetCode(_ code: String) async throws {
        try await apiClient.requestVoid(
            path: "/auth/password/reset/verify",
            method: "POST",
            body: ["code": code]
        )
    }

    /// Reset password using code
    /// - Parameters:
    ///   - code: The code from the password reset email
    ///   - password: The new password
    public func resetPassword(code: String, password: String) async throws {
        try await apiClient.requestVoid(
            path: "/auth/password/reset",
            method: "POST",
            body: [
                "code": code,
                "password": password
            ]
        )
    }

    // MARK: - Email Verification

    /// Verify email with code
    /// - Parameter code: The verification code from the email
    public func verifyEmail(code: String) async throws {
        try await apiClient.requestVoid(
            path: "/auth/email-verification/verify",
            method: "POST",
            body: ["code": code]
        )
    }

    // MARK: - Team Invitation Methods

    /// Get team invitation details
    public func getTeamInvitationDetails(code: String) async throws -> TeamInvitation {
        return try await withTokenRefresh {
            try await self.apiClient.request(
                path: "/teams/invitations/\(code)",
                method: "GET"
            )
        }
    }

    /// Verify team invitation code
    public func verifyTeamInvitationCode(_ code: String) async throws -> Bool {
        struct VerifyResponse: Decodable {
            let valid: Bool
        }

        let response: VerifyResponse = try await withTokenRefresh {
            try await self.apiClient.request(
                path: "/teams/invitations/\(code)/verify",
                method: "POST"
            )
        }

        return response.valid
    }

    /// Accept team invitation
    public func acceptTeamInvitation(code: String) async throws -> Team {
        let accessToken = await tokenStore.getAccessToken()

        let team: Team = try await withTokenRefresh {
            try await self.apiClient.request(
                path: "/teams/invitations/\(code)/accept",
                method: "POST",
                accessToken: accessToken
            )
        }

        team.app = self
        return team
    }

    // MARK: - Project Methods

    /// Get project configuration
    public func getProject() async throws -> Project {
        if let cached = cachedProject {
            return cached
        }

        // Use task to avoid multiple concurrent fetches
        if let existingTask = projectFetchTask {
            return try await existingTask.value
        }

        let task = Task<Project, Error> {
            let project: Project = try await withTokenRefresh {
                try await self.apiClient.request(
                    path: "/projects/\(self.projectId)",
                    method: "GET"
                )
            }
            self.cachedProject = project
            self.projectFetchTask = nil
            return project
        }

        projectFetchTask = task
        return try await task.value
    }

    // MARK: - Token Methods

    /// Get the current access token
    public func getAccessToken() async -> String? {
        return await tokenStore.getAccessToken()
    }

    /// Get the current refresh token
    public func getRefreshToken() async -> String? {
        return await tokenStore.getRefreshToken()
    }

    /// Get authentication headers for manual API requests
    public func getAuthHeaders() async -> [String: String] {
        var headers: [String: String] = [:]

        if let accessToken = await tokenStore.getAccessToken() {
            headers["x-stack-access-token"] = accessToken
        }

        if let refreshToken = await tokenStore.getRefreshToken() {
            headers["x-stack-refresh-token"] = refreshToken
        }

        headers["x-stack-project-id"] = projectId
        headers["x-stack-publishable-client-key"] = publishableClientKey

        return headers
    }

    // MARK: - Subscription Methods

    /// Cancel a subscription
    public func cancelSubscription(subscriptionId: String) async throws {
        let accessToken = await tokenStore.getAccessToken()

        try await withTokenRefresh {
            try await self.apiClient.requestVoid(
                path: "/subscriptions/\(subscriptionId)/cancel",
                method: "POST",
                accessToken: accessToken
            )
        }
    }

    // MARK: - Product/Item Methods (Client)

    /// Get an item by ID for the current user
    public func getItem(itemId: String) async throws -> Item {
        let user = try await getUser(or: .throw)
        guard let user = user else {
            throw StackAuthAPIError.userNotSignedIn()
        }

        return try await user.getItem(itemId: itemId)
    }

    /// List products for the current user
    public func listProducts(cursor: String? = nil, limit: Int? = nil) async throws -> CustomerProductsList {
        let user = try await getUser(or: .throw)
        guard let user = user else {
            throw StackAuthAPIError.userNotSignedIn()
        }

        return try await user.listProducts(cursor: cursor, limit: limit)
    }

    // MARK: - Token Refresh

    /// Execute a request with automatic token refresh on 401
    internal func withTokenRefresh<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as StackAuthAPIError {
            // Only retry if it's an access token expired error
            guard error.code == "access_token_expired" else {
                throw error
            }

            // Try to refresh the token
            guard let refreshToken = await tokenStore.getRefreshToken() else {
                throw error
            }

            do {
                let response: TokenRefreshResponse = try await apiClient.request(
                    path: "/auth/token/refresh",
                    method: "POST",
                    refreshToken: refreshToken
                )

                // Update tokens
                await tokenStore.setTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken ?? refreshToken
                )

                // Retry the operation
                return try await operation()
            } catch {
                // If refresh fails, clear tokens
                await tokenStore.clearTokens()
                throw error
            }
        }
    }
}

/// Token refresh response - moved outside generic function
private struct TokenRefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
}

// Note: Team, ContactChannel, and OAuthProvider classes have weak app references
// that are set when instances are created or returned from API calls.
// These references allow those objects to make authenticated requests back to the API.
