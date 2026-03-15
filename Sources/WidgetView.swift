import SwiftUI

struct WidgetView: View {
    let store: HealthStore
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            contentSection
            ResizeHandle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await store.refresh() }
        .onReceive(timer) { _ in
            Task { await store.refresh() }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 6) {
            Text("Kafka")
                .font(.title3)
                .fontWeight(.bold)

            Circle()
                .fill(store.overallStatus.color)
                .frame(width: 8, height: 8)

            Spacer()

            if let date = store.lastRefresh {
                Text(date, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            headerMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var headerMenu: some View {
        Menu {
            Button("Refresh") {
                Task { await store.refresh() }
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }

    @ViewBuilder
    private var contentSection: some View {
        if !store.configLoaded {
            Spacer()
            VStack(spacing: 8) {
                Text("Configure clusters in")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("~/.config/kafka-health-widget/config.json")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        } else if store.clusters.isEmpty {
            Spacer()
            ProgressView()
                .scaleEffect(0.7)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.clusters) { cluster in
                        ClusterRow(health: cluster)
                        if cluster.id != store.clusters.last?.id {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
            }
        }
    }
}
