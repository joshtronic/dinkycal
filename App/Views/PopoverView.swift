import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonthHeaderView()
            MonthGridView()
        }
        .padding(14)
        .frame(width: 286)
    }
}
