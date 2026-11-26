import SwiftUI

struct MonthHeaderView: View {
    @EnvironmentObject var model: CalendarModel

    var body: some View {
        HStack(spacing: 6) {
            Text(model.monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 15, weight: .bold))
            Spacer()
            if !model.isOnCurrentMonth {
                Button("Today") { model.goToToday() }
                    .buttonStyle(PillButtonStyle())
            }
            Button { model.showPreviousMonth() } label: { Image(systemName: "chevron.left") }
                .buttonStyle(RoundIconButtonStyle())
                .help("Previous month")
            Button { model.showNextMonth() } label: { Image(systemName: "chevron.right") }
                .buttonStyle(RoundIconButtonStyle())
                .help("Next month")
        }
    }
}

/// Flat, rounded, GNOME-ish buttons: no chrome until hovered.
struct RoundIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverBackground(shape: Circle(), pressed: configuration.isPressed) {
            configuration.label
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverBackground(shape: Capsule(), pressed: configuration.isPressed, resting: 0.08) {
            configuration.label
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .frame(height: 26)
        }
    }
}

struct HoverBackground<S: Shape, Content: View>: View {
    let shape: S
    let pressed: Bool
    var resting: Double = 0
    @ViewBuilder let content: () -> Content
    @State private var hovering = false

    var body: some View {
        content()
            .contentShape(shape)
            .background(shape.fill(Color.primary.opacity(pressed ? 0.2 : hovering ? 0.12 : resting)))
            .onHover { hovering = $0 }
    }
}
