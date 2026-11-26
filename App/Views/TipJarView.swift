import StoreKit
import SwiftUI

/// "Support Dinky Cal": three optional tips. Never shown unless the user opens it.
struct TipJarView: View {
    @ObservedObject var tipJar: TipJar

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support Dinky Cal").font(.system(size: 17, weight: .bold))
                    Text("Everything in Dinky Cal is free, and stays free. If it's useful to you, a tip helps an indie developer keep it going. It doesn't unlock anything.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            switch tipJar.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading tips…").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 96)
            case .unavailable:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tips aren't available right now.").font(.system(size: 13, weight: .semibold))
                    Text("Check your connection and try again later. Thanks for thinking of it either way.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    Button("Try Again") { Task { await tipJar.load() } }
                }
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            case .ready:
                HStack(spacing: 10) {
                    ForEach(tipJar.items) { item in
                        TipButton(name: item.name, price: item.price, busy: tipJar.purchasing == item.id) {
                            if let product = item.product { Task { await tipJar.buy(product) } }
                        }
                        .disabled(tipJar.purchasing != nil)
                    }
                }
            }

            Group {
                switch tipJar.result {
                case .none: EmptyView()
                case .thanks: Label("Thank you! You're a Dinky Cal supporter.", systemImage: "heart.fill").foregroundStyle(.pink)
                case .pending: Label("Waiting for approval. Thanks!", systemImage: "clock")
                case let .failed(message): Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 12.5, weight: .medium))
        }
        .padding(22)
        .frame(width: 400)
        .task { await tipJar.load() }
    }
}

private struct TipButton: View {
    let name: String
    let price: String
    let busy: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                if busy {
                    ProgressView().controlSize(.small).frame(height: 22)
                } else {
                    Text(price).font(.system(size: 18, weight: .bold).monospacedDigit())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(hovering ? 0.2 : 0.12)))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
