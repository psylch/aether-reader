import SwiftUI

struct PageIndicatorView: View {
    let current: Int
    let total: Int

    var body: some View {
        Text("\(current) / \(total)")
            .font(.caption)
            .fontWeight(.semibold)
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(in: .capsule)
    }
}
