import Foundation

// MARK: - Customer Protocol

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

// MARK: - Item

public class Item: Codable {
    public let id: String?
    public let displayName: String
    public var quantity: Int

    public var nonNegativeQuantity: Int {
        return max(0, quantity)
    }

    public init(id: String? = nil, displayName: String, quantity: Int) {
        self.id = id
        self.displayName = displayName
        self.quantity = quantity
    }
}

// MARK: - ServerItem

public class ServerItem: Item {
    weak var app: StackServerApp?
    public let customerId: String
    public let customerType: String

    public init(from item: Item, app: StackServerApp?, customerId: String, customerType: String) {
        self.app = app
        self.customerId = customerId
        self.customerType = customerType
        super.init(id: item.id, displayName: item.displayName, quantity: item.quantity)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customerId = try container.decode(String.self, forKey: .customerId)
        self.customerType = try container.decode(String.self, forKey: .customerType)
        try super.init(from: decoder)
    }

    enum CodingKeys: String, CodingKey {
        case customerId, customerType
    }

    public func increaseQuantity(_ amount: Int) async throws {
        guard let app = app, let itemId = id else { return }
        try await app.apiClient.requestVoid(
            path: "/customers/\(customerType)/\(customerId)/items/\(itemId)/quantity",
            method: "POST",
            body: ["change": amount],
            isServerOnly: true
        )
        self.quantity += amount
    }

    public func decreaseQuantity(_ amount: Int) async throws {
        guard let app = app, let itemId = id else { return }
        try await app.apiClient.requestVoid(
            path: "/customers/\(customerType)/\(customerId)/items/\(itemId)/quantity",
            method: "POST",
            body: ["change": -amount],
            isServerOnly: true
        )
        self.quantity -= amount
    }

    public func tryDecreaseQuantity(_ amount: Int) async throws -> Bool {
        guard let app = app, let itemId = id else { return false }

        struct TryDecreaseResponse: Decodable {
            let success: Bool
        }

        let response: TryDecreaseResponse = try await app.apiClient.request(
            path: "/customers/\(customerType)/\(customerId)/items/\(itemId)/try-decrease",
            method: "POST",
            body: ["amount": amount],
            isServerOnly: true
        )

        if response.success {
            self.quantity -= amount
        }
        return response.success
    }
}

// MARK: - CustomerBilling

public struct CustomerBilling: Codable {
    public let hasCustomer: Bool
    public let defaultPaymentMethod: CustomerDefaultPaymentMethod?
}

public struct CustomerDefaultPaymentMethod: Codable {
    public let id: String
    public let brand: String?
    public let last4: String?
    public let expMonth: Int?
    public let expYear: Int?
}

// MARK: - CustomerProduct

public struct CustomerProduct: Codable {
    public let id: String?
    public let quantity: Int
    public let displayName: String
    public let customerType: String
    public let isServerOnly: Bool
    public let stackable: Bool
    public let type: String
    public let subscription: SubscriptionInfo?
    public let switchOptions: [SwitchOption]?
}

public struct SubscriptionInfo: Codable {
    public let currentPeriodEnd: Date?
    public let cancelAtPeriodEnd: Bool
    public let isCancelable: Bool
}

public struct SwitchOption: Codable {
    public let productId: String
    public let displayName: String
    public let prices: [Price]
}

public struct Price: Codable {
    public let amount: Int
    public let currency: String
    public let interval: String?
}

public struct CustomerProductsList: Codable {
    public let products: [CustomerProduct]
    public let nextCursor: String?

    public init(products: [CustomerProduct], nextCursor: String?) {
        self.products = products
        self.nextCursor = nextCursor
    }
}

// MARK: - InlineProduct

public struct InlineProduct: Codable {
    public let displayName: String
    public let type: String
    public let isServerOnly: Bool?
    public let stackable: Bool?
    public let prices: [InlinePrice]

    public init(displayName: String, type: String, isServerOnly: Bool? = nil, stackable: Bool? = nil, prices: [InlinePrice]) {
        self.displayName = displayName
        self.type = type
        self.isServerOnly = isServerOnly
        self.stackable = stackable
        self.prices = prices
    }
}

public struct InlinePrice: Codable {
    public let amount: Int
    public let currency: String
    public let interval: String?

    public init(amount: Int, currency: String, interval: String? = nil) {
        self.amount = amount
        self.currency = currency
        self.interval = interval
    }
}
