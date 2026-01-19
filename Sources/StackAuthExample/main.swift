import Foundation
import StackAuth

@main
struct StackAuthExample {
    static func main() async {
        print("Stack Auth Swift SDK - Example Usage\n")
        print("=====================================\n")

        // Initialize the client SDK
        let clientApp = StackClientApp(
            projectId: "test-project-id",
            publishableClientKey: "test-publishable-key",
            tokenStore: .memory
        )

        print("✅ StackClientApp initialized")
        print("   - Project ID: test-project-id")
        print("   - Token Store: memory")
        print("")

        // Example 1: Get user (without actual authentication)
        print("Example 1: Get User")
        print("-------------------")
        do {
            let user = try await clientApp.getUser(or: .returnNull)
            if let user = user {
                print("✅ User found: \(user.displayName ?? "No name")")
                print("   - Email: \(user.primaryEmail ?? "No email")")
                print("   - ID: \(user.id)")
            } else {
                print("ℹ️  No user authenticated (expected)")
            }
        } catch {
            print("❌ Error: \(error)")
        }
        print("")

        // Example 2: Server-side SDK
        print("Example 2: Server SDK")
        print("---------------------")
        let serverApp = StackServerApp(
            projectId: "test-project-id",
            publishableClientKey: "test-publishable-key",
            secretServerKey: "test-secret-key"
        )
        print("✅ StackServerApp initialized")
        print("   - Has server capabilities: true")
        print("")

        // Example 3: Token management
        print("Example 3: Token Management")
        print("---------------------------")
        let accessToken = await clientApp.getAccessToken()
        let refreshToken = await clientApp.getRefreshToken()
        print("Access Token: \(accessToken ?? "None")")
        print("Refresh Token: \(refreshToken ?? "None")")
        print("")

        // Example 4: Create inline product
        print("Example 4: Payment Types")
        print("------------------------")
        let inlineProduct = InlineProduct(
            displayName: "Premium Plan",
            type: "subscription",
            isServerOnly: false,
            stackable: false,
            prices: [
                InlinePrice(amount: 1999, currency: "usd", interval: "month")
            ]
        )
        print("✅ Created inline product: \(inlineProduct.displayName)")
        print("   - Type: \(inlineProduct.type)")
        print("   - Price: $\(Double(inlineProduct.prices[0].amount) / 100)/\(inlineProduct.prices[0].interval ?? "once")")
        print("")

        // Example 5: Item tracking
        print("Example 5: Item Tracking")
        print("------------------------")
        let item = Item(id: "credits", displayName: "API Credits", quantity: 100)
        print("✅ Created item: \(item.displayName)")
        print("   - Quantity: \(item.quantity)")
        print("   - Non-negative quantity: \(item.nonNegativeQuantity)")

        // Simulate negative balance
        item.quantity = -50
        print("   - After overdraft: \(item.quantity)")
        print("   - Non-negative (for display): \(item.nonNegativeQuantity)")
        print("")

        // Example 6: Error handling
        print("Example 6: Error Handling")
        print("-------------------------")
        let error = StackAuthAPIError.emailPasswordMismatch()
        print("Error code: \(error.code)")
        print("Error message: \(error.message)")
        print("")

        // Example 7: Project configuration
        print("Example 7: Project Configuration")
        print("--------------------------------")
        print("Attempting to fetch project configuration...")
        do {
            let project = try await clientApp.getProject()
            print("✅ Project: \(project.displayName)")
            print("   - Sign-up enabled: \(project.config.signUpEnabled)")
            print("   - Credential auth: \(project.config.credentialEnabled)")
            print("   - Magic link: \(project.config.magicLinkEnabled)")
            print("   - Passkey: \(project.config.passkeyEnabled)")
            print("   - OAuth providers: \(project.config.oauthProviders.count)")
        } catch {
            print("ℹ️  Could not fetch project (expected without real API): \(error)")
        }
        print("")

        print("=====================================")
        print("Example completed successfully!")
        print("")
        print("Documentation:")
        print("- See README.md for usage guide")
        print("- See specs/*.spec.md for detailed API reference")
        print("- All types support async/await")
        print("- Built-in token refresh on expiration")
    }
}
