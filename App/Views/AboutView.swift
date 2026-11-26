import SwiftUI

struct AboutView: View {
    var isSupporter = false
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)
            Text("Dinky Cal").font(.system(size: 20, weight: .bold))
            Text(version).font(.caption).foregroundStyle(.secondary)
            if isSupporter {
                Label("Supporter. Thank you!", systemImage: "heart.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.pink)
            }
            Text("A tiny month calendar for your menu bar.")
                .font(.system(size: 13))
            VStack(spacing: 4) {
                Link("dinkycal.com", destination: URL(string: "https://dinkycal.com/")!)
                Link("Support", destination: URL(string: "https://dinkycal.com/support")!)
                Link("Privacy Policy", destination: URL(string: "https://dinkycal.com/privacy")!)
                Link("Source on GitHub", destination: URL(string: "https://github.com/joshtronic/dinkycal")!)
                Link("Made by joshtronic", destination: URL(string: "https://joshtronic.com/")!)
            }
            .font(.system(size: 12))
            .padding(.top, 4)
            Text("Free software, licensed under\nthe GPL-3.0-or-later.")
                .font(.caption2).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 300)
    }
}
