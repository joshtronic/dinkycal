import DinkyCalCore
import Foundation
import StoreKit

/// Optional tips through the App Store. Nothing is ever unlocked; a tip only earns the
/// "Supporter" heart in About. No data leaves the Mac except Apple's own purchase flow.
@MainActor
final class TipJar: ObservableObject {
    enum LoadState { case loading, ready, unavailable }
    enum Result: Equatable { case none, thanks, pending, failed(String) }

    @Published private(set) var products: [Product] = []
    @Published private(set) var state: LoadState = .loading
    @Published private(set) var result: Result = .none
    @Published private(set) var purchasing: Product.ID?
    @Published private(set) var isSupporter: Bool

    private let defaults: UserDefaults
    private var updates: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSupporter = defaults.bool(forKey: "isSupporter")
        // Purchases can finish outside the window (interrupted, Ask to Buy): always listen.
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    deinit { updates?.cancel() }

    /// What the window lists: real products, or (DEBUG screenshots only) stand-ins.
    struct Item: Identifiable { let id: String; let name: String; let price: String; let product: Product? }

    var items: [Item] {
        #if DEBUG
        if let preview = previewItems { return preview }
        #endif
        return products.map { Item(id: $0.id, name: $0.displayName, price: $0.displayPrice, product: $0) }
    }

    #if DEBUG
    private var previewItems: [Item]?
    func showPreviewItems() {
        previewItems = [("small", "Small Tip", "$0.99"), ("medium", "Medium Tip", "$2.99"), ("large", "Large Tip", "$4.99")]
            .map { Item(id: $0.0, name: $0.1, price: $0.2, product: nil) }
        state = .ready
    }
    #endif

    func load() async {
        guard products.isEmpty, items.isEmpty else { return }
        state = .loading
        do {
            let loaded = try await Product.products(for: TipCatalog.productIDs)
            products = TipCatalog.ordered(loaded, id: \.id)
            state = products.isEmpty ? .unavailable : .ready
        } catch {
            state = .unavailable
        }
    }

    func buy(_ product: Product) async {
        purchasing = product.id
        result = .none
        defer { purchasing = nil }
        do {
            switch try await product.purchase() {
            case let .success(verification):
                await handle(verification)
            case .pending:
                result = .pending
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            result = .failed(error.localizedDescription)
        }
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = verification else {
            result = .failed("The App Store couldn't verify that purchase.")
            return
        }
        await transaction.finish()
        guard TipCatalog.productIDs.contains(transaction.productID), transaction.revocationDate == nil else { return }
        isSupporter = true
        defaults.set(true, forKey: "isSupporter")
        result = .thanks
    }
}
