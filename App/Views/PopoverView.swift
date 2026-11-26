import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var model: CalendarModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonthHeaderView()
            MonthGridView()
            Divider()
            DayDetailView()
        }
        .padding(14)
        .frame(width: 300)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(phases: .down) { press in handle(press) }
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        let command = press.modifiers.contains(.command)
        switch press.key {
        case .leftArrow: command ? model.showPreviousMonth() : model.moveSelection(byDays: -1)
        case .rightArrow: command ? model.showNextMonth() : model.moveSelection(byDays: 1)
        case .upArrow: model.moveSelection(byDays: -7)
        case .downArrow: model.moveSelection(byDays: 7)
        case .escape: model.closePopover()
        case KeyEquivalent("t"): model.goToToday()
        default: return .ignored
        }
        return .handled
    }
}
