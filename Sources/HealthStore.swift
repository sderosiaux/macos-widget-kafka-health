import Foundation
import Observation

@Observable
final class HealthStore {
    var clusters: [ClusterHealth] = []
    var lastRefresh: Date?
    var configLoaded = false
    var refreshInterval: Int = 60

    private var config: WidgetConfig?

    init() {
        loadConfig()
    }

    func loadConfig() {
        config = WidgetConfig.load()
        configLoaded = config != nil
        if let cfg = config {
            refreshInterval = cfg.interval
        }
    }

    var overallStatus: ClusterStatus {
        guard !clusters.isEmpty else { return .unknown }
        return clusters.max { $0.status.severity < $1.status.severity }?.status ?? .unknown
    }

    @MainActor
    func refresh() async {
        guard let cfg = config else {
            loadConfig()
            return
        }

        let results = await withTaskGroup(of: ClusterHealth.self, returning: [ClusterHealth].self) { group in
            for cluster in cfg.clusters {
                group.addTask {
                    await ConduktorService.fetchHealth(for: cluster)
                }
            }
            var collected: [ClusterHealth] = []
            for await result in group {
                collected.append(result)
                ConduktorService.updateCache(result)
            }
            return collected
        }

        clusters = results.sorted { $0.clusterName < $1.clusterName }
        lastRefresh = Date()
    }
}
