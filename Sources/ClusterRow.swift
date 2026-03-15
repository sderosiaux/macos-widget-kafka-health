import SwiftUI

struct ClusterRow: View {
    let health: ClusterHealth
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            clusterHeader
            metricsRow
            alertsSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { openConsole() }
    }

    private var clusterHeader: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(health.status.color)
                .frame(width: 8, height: 8)

            Text(health.clusterName)
                .font(.body)
                .fontWeight(.bold)
                .lineLimit(1)

            environmentBadge

            Spacer()

            Text(health.status.label)
                .font(.caption)
                .foregroundStyle(health.status.color)
        }
    }

    private var environmentBadge: some View {
        Text(health.environment.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(health.environment.badgeColor.opacity(0.15))
            .foregroundStyle(health.environment.badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricLabel("Brokers", value: "\(health.brokerCount)")
            metricLabel("Topics", value: "\(health.topicCount)")
            metricLabel("Groups", value: "\(health.consumerGroupCount)")
            if let lag = health.totalLag, lag > 0 {
                metricLabel("Lag", value: formatLag(lag))
            }
        }
    }

    private func metricLabel(_ label: String, value: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var alertsSection: some View {
        if health.offlinePartitions > 0 {
            alertText("Offline partitions: \(health.offlinePartitions)", color: .red)
        }
        if health.underReplicatedPartitions > 0 {
            alertText("Under-replicated: \(health.underReplicatedPartitions)", color: .orange)
        }
    }

    private func alertText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(color)
    }

    private func formatLag(_ lag: Int64) -> String {
        if lag >= 1_000_000 {
            return String(format: "%.1fM", Double(lag) / 1_000_000)
        } else if lag >= 1_000 {
            return String(format: "%.1fK", Double(lag) / 1_000)
        }
        return "\(lag)"
    }

    private func openConsole() {
        guard let url = URL(string: health.baseUrl) else { return }
        NSWorkspace.shared.open(url)
    }
}
