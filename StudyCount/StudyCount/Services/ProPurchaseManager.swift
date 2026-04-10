import Combine
import Foundation
import StoreKit

@MainActor
final class ProPurchaseManager: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []

    private var updates: Task<Void, Never>?

    init() {
        updates = Task { await observeTransactions() }
        Task { await loadProducts(); await refreshEntitlements() }
    }

    deinit {
        updates?.cancel()
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [AppConstants.proProductId])
        } catch {
            products = []
        }
    }

    func refreshEntitlements() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == AppConstants.proProductId {
                found = true
                break
            }
        }
        isPro = found
    }

    func purchase() async throws {
        guard let product = products.first else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result {
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }
}
