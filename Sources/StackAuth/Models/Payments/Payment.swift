import Foundation

/// Represents a subscription for a user or team
public struct Subscription: Codable, Identifiable, Equatable {
    /// Unique identifier for the subscription
    public let id: String

    /// User or team ID this subscription belongs to
    public let subscriberId: String

    /// Type of subscriber (user or team)
    public let subscriberType: SubscriberType

    /// Plan ID
    public let planId: String

    /// Plan name
    public let planName: String

    /// Subscription status
    public let status: SubscriptionStatus

    /// Current billing period start
    public let currentPeriodStart: Date

    /// Current billing period end
    public let currentPeriodEnd: Date

    /// Whether the subscription will auto-renew
    public let autoRenew: Bool

    /// When the subscription was created
    public let createdAt: Date

    /// When the subscription was last updated
    public let updatedAt: Date

    /// When the subscription was canceled (if applicable)
    public let canceledAt: Date?

    /// When the subscription will end (if not renewing)
    public let endsAt: Date?

    /// Trial end date (if applicable)
    public let trialEndsAt: Date?

    /// Payment method ID
    public let paymentMethodId: String?

    /// Amount in cents
    public let amount: Int

    /// Currency code (e.g., "usd")
    public let currency: String

    /// Billing interval
    public let interval: BillingInterval

    /// Metadata
    public let metadata: [String: AnyCodable]?

    public init(
        id: String,
        subscriberId: String,
        subscriberType: SubscriberType,
        planId: String,
        planName: String,
        status: SubscriptionStatus,
        currentPeriodStart: Date,
        currentPeriodEnd: Date,
        autoRenew: Bool,
        createdAt: Date,
        updatedAt: Date,
        canceledAt: Date?,
        endsAt: Date?,
        trialEndsAt: Date?,
        paymentMethodId: String?,
        amount: Int,
        currency: String,
        interval: BillingInterval,
        metadata: [String: AnyCodable]?
    ) {
        self.id = id
        self.subscriberId = subscriberId
        self.subscriberType = subscriberType
        self.planId = planId
        self.planName = planName
        self.status = status
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.autoRenew = autoRenew
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.canceledAt = canceledAt
        self.endsAt = endsAt
        self.trialEndsAt = trialEndsAt
        self.paymentMethodId = paymentMethodId
        self.amount = amount
        self.currency = currency
        self.interval = interval
        self.metadata = metadata
    }

    /// Check if the subscription is active
    public var isActive: Bool {
        return status == .active || status == .trialing
    }

    /// Check if the subscription is in a trial period
    public var isTrialing: Bool {
        guard let trialEndsAt = trialEndsAt else {
            return false
        }
        return status == .trialing && trialEndsAt > Date()
    }
}

/// Type of subscriber
public enum SubscriberType: String, Codable {
    case user
    case team
}

/// Subscription status
public enum SubscriptionStatus: String, Codable {
    case active
    case trialing
    case pastDue = "past_due"
    case canceled
    case unpaid
    case incomplete
    case incompleteExpired = "incomplete_expired"
    case paused
}

/// Billing interval
public enum BillingInterval: String, Codable {
    case day
    case week
    case month
    case year
}

/// Payment method
public struct PaymentMethod: Codable, Identifiable, Equatable {
    /// Unique identifier for the payment method
    public let id: String

    /// Type of payment method
    public let type: PaymentMethodType

    /// Whether this is the default payment method
    public let isDefault: Bool

    /// Card details (if type is card)
    public let card: CardDetails?

    /// Bank account details (if type is bank account)
    public let bankAccount: BankAccountDetails?

    /// When this payment method was created
    public let createdAt: Date

    /// When this payment method expires (if applicable)
    public let expiresAt: Date?

    public init(
        id: String,
        type: PaymentMethodType,
        isDefault: Bool,
        card: CardDetails?,
        bankAccount: BankAccountDetails?,
        createdAt: Date,
        expiresAt: Date?
    ) {
        self.id = id
        self.type = type
        self.isDefault = isDefault
        self.card = card
        self.bankAccount = bankAccount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

/// Payment method type
public enum PaymentMethodType: String, Codable {
    case card
    case bankAccount = "bank_account"
    case paypal
    case applePay = "apple_pay"
    case googlePay = "google_pay"
}

/// Card details
public struct CardDetails: Codable, Equatable {
    /// Card brand (Visa, MasterCard, etc.)
    public let brand: String

    /// Last 4 digits of the card
    public let last4: String

    /// Expiration month (1-12)
    public let expirationMonth: Int

    /// Expiration year
    public let expirationYear: Int

    /// Cardholder name
    public let cardholderName: String?

    /// Billing address
    public let billingAddress: Address?

    public init(
        brand: String,
        last4: String,
        expirationMonth: Int,
        expirationYear: Int,
        cardholderName: String?,
        billingAddress: Address?
    ) {
        self.brand = brand
        self.last4 = last4
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.cardholderName = cardholderName
        self.billingAddress = billingAddress
    }

    /// Check if the card is expired
    public var isExpired: Bool {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        let currentYear = components.year!
        let currentMonth = components.month!

        if expirationYear < currentYear {
            return true
        }
        if expirationYear == currentYear && expirationMonth < currentMonth {
            return true
        }
        return false
    }
}

/// Bank account details
public struct BankAccountDetails: Codable, Equatable {
    /// Bank name
    public let bankName: String?

    /// Last 4 digits of account number
    public let last4: String

    /// Account holder name
    public let accountHolderName: String?

    /// Account type
    public let accountType: BankAccountType?

    public init(
        bankName: String?,
        last4: String,
        accountHolderName: String?,
        accountType: BankAccountType?
    ) {
        self.bankName = bankName
        self.last4 = last4
        self.accountHolderName = accountHolderName
        self.accountType = accountType
    }
}

/// Bank account type
public enum BankAccountType: String, Codable {
    case checking
    case savings
}

/// Address
public struct Address: Codable, Equatable {
    /// Street address line 1
    public let line1: String

    /// Street address line 2
    public let line2: String?

    /// City
    public let city: String

    /// State/Province
    public let state: String?

    /// Postal/ZIP code
    public let postalCode: String

    /// Country code (ISO 3166-1 alpha-2)
    public let country: String

    public init(
        line1: String,
        line2: String?,
        city: String,
        state: String?,
        postalCode: String,
        country: String
    ) {
        self.line1 = line1
        self.line2 = line2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
}

/// Invoice
public struct Invoice: Codable, Identifiable, Equatable {
    /// Unique identifier for the invoice
    public let id: String

    /// Subscription ID this invoice is for
    public let subscriptionId: String?

    /// Invoice number
    public let number: String

    /// Invoice status
    public let status: InvoiceStatus

    /// Amount due in cents
    public let amountDue: Int

    /// Amount paid in cents
    public let amountPaid: Int

    /// Currency code
    public let currency: String

    /// Invoice date
    public let date: Date

    /// Due date
    public let dueDate: Date?

    /// When the invoice was paid
    public let paidAt: Date?

    /// URL to view the invoice
    public let hostedInvoiceUrl: String?

    /// PDF download URL
    public let invoicePdfUrl: String?

    /// Line items
    public let lineItems: [InvoiceLineItem]

    public init(
        id: String,
        subscriptionId: String?,
        number: String,
        status: InvoiceStatus,
        amountDue: Int,
        amountPaid: Int,
        currency: String,
        date: Date,
        dueDate: Date?,
        paidAt: Date?,
        hostedInvoiceUrl: String?,
        invoicePdfUrl: String?,
        lineItems: [InvoiceLineItem]
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.number = number
        self.status = status
        self.amountDue = amountDue
        self.amountPaid = amountPaid
        self.currency = currency
        self.date = date
        self.dueDate = dueDate
        self.paidAt = paidAt
        self.hostedInvoiceUrl = hostedInvoiceUrl
        self.invoicePdfUrl = invoicePdfUrl
        self.lineItems = lineItems
    }
}

/// Invoice status
public enum InvoiceStatus: String, Codable {
    case draft
    case open
    case paid
    case uncollectible
    case void
}

/// Invoice line item
public struct InvoiceLineItem: Codable, Identifiable, Equatable {
    /// Unique identifier
    public let id: String

    /// Description
    public let description: String

    /// Amount in cents
    public let amount: Int

    /// Quantity
    public let quantity: Int

    /// Unit amount in cents
    public let unitAmount: Int

    public init(
        id: String,
        description: String,
        amount: Int,
        quantity: Int,
        unitAmount: Int
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.quantity = quantity
        self.unitAmount = unitAmount
    }
}
