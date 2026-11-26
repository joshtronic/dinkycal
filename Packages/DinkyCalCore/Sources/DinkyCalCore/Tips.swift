import Foundation

/// The App Store tip products. Tips unlock nothing; they're a thank-you.
public enum TipCatalog {
    public static let productIDs = [
        "com.joshtronic.dinkycal.tip.small",
        "com.joshtronic.dinkycal.tip.medium",
        "com.joshtronic.dinkycal.tip.large",
    ]

    /// Puts items in catalog order (small, medium, large) and drops anything not in the catalog.
    public static func ordered<T>(_ items: [T], id: (T) -> String) -> [T] {
        items
            .compactMap { item in productIDs.firstIndex(of: id(item)).map { ($0, item) } }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }
}
