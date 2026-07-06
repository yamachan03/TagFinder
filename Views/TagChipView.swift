import SwiftUI

struct TagChipView: View {
    let name: String
    let colorIndex: Int?

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(FinderTagColor.color(for: colorIndex))
                .frame(width: 8, height: 8)
            Text(name)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.12), in: Capsule())
    }
}
