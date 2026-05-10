import SwiftUI

struct MenuHeaderView: View {
    let snapshot: DashboardSnapshot
    let history: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("vCPU")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Self.vcpuText(self.snapshot.usage.activeVCPU))
                        .font(.system(size: 30, weight: .semibold, design: .monospaced))
                }
                .fixedSize(horizontal: true, vertical: false)
                Spacer()
                Sparkline(values: self.history)
                    .frame(width: 138, height: 34)
                    .padding(.bottom, 5)
            }

            HStack(spacing: 7) {
                Circle()
                    .fill(self.snapshot.isOperational ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(self.snapshot.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 320, alignment: .leading)
    }

    private static func vcpuText(_ value: Int) -> String {
        String(value)
    }
}

struct Sparkline: View {
    var values: [Int]

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(self.values.max() ?? 1, 1)
            let count = max(self.values.count, 1)
            let barWidth = max(2, proxy.size.width / CGFloat(max(count, 24)) - 1)

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(self.values.suffix(48).enumerated()), id: \.offset) { _, value in
                    Capsule()
                        .fill(value == 0 ? Color.secondary.opacity(0.24) : Color.cyan)
                        .frame(
                            width: barWidth,
                            height: max(2, proxy.size.height * CGFloat(value) / CGFloat(maxValue))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}
