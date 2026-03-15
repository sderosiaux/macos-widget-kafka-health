import Foundation

enum ConduktorService {
    // MARK: - API Response Types

    private struct ClusterListResponse: Decodable {
        let clusters: [ClusterInfo]?
    }

    private struct ClusterInfo: Decodable {
        let id: String?
        let name: String?
        let brokers: Int?
    }

    private struct HealthResponse: Decodable {
        let status: String?
        let underReplicatedPartitions: Int?
        let offlinePartitions: Int?
        let topicCount: Int?
        let consumerGroupCount: Int?
    }

    private struct ConsumerGroupsResponse: Decodable {
        let consumerGroups: [ConsumerGroupInfo]?
    }

    private struct ConsumerGroupInfo: Decodable {
        let lag: Int64?
    }

    // MARK: - Public

    static func fetchHealth(for cluster: ClusterConfig) async -> ClusterHealth {
        async let clustersResult = fetchClusters(cluster)
        async let healthResult = fetchClusterHealth(cluster)
        async let lagResult = fetchTotalLag(cluster)

        let clusters = await clustersResult
        let health = await healthResult
        let lag = await lagResult

        let brokerCount = clusters?.brokers ?? 0
        let topicCount = health?.topicCount ?? 0
        let consumerGroupCount = health?.consumerGroupCount ?? 0
        let underReplicated = health?.underReplicatedPartitions ?? 0
        let offline = health?.offlinePartitions ?? 0

        let status = determineStatus(
            connected: health != nil || clusters != nil,
            offlinePartitions: offline,
            underReplicated: underReplicated,
            totalLag: lag
        )

        return ClusterHealth(
            clusterName: cluster.name,
            environment: cluster.environment,
            baseUrl: cluster.baseUrl,
            status: status,
            brokerCount: brokerCount,
            topicCount: topicCount,
            consumerGroupCount: consumerGroupCount,
            underReplicatedPartitions: underReplicated,
            offlinePartitions: offline,
            totalLag: lag,
            lastChecked: Date()
        )
    }

    // MARK: - Private API Calls

    private static func fetchClusters(_ config: ClusterConfig) async -> ClusterInfo? {
        guard let data = await apiGet(config, path: "/api/v1/clusters") else { return nil }
        if let list = try? JSONDecoder().decode([ClusterInfo].self, from: data) {
            let total = list.reduce(0) { $0 + ($1.brokers ?? 0) }
            return ClusterInfo(id: list.first?.id, name: list.first?.name, brokers: total)
        }
        if let response = try? JSONDecoder().decode(ClusterListResponse.self, from: data) {
            let items = response.clusters ?? []
            let total = items.reduce(0) { $0 + ($1.brokers ?? 0) }
            return ClusterInfo(id: items.first?.id, name: items.first?.name, brokers: total)
        }
        return nil
    }

    private static func fetchClusterHealth(_ config: ClusterConfig) async -> HealthResponse? {
        guard let data = await apiGet(config, path: "/api/v1/clusters/health") else { return nil }
        return try? JSONDecoder().decode(HealthResponse.self, from: data)
    }

    private static func fetchTotalLag(_ config: ClusterConfig) async -> Int64? {
        guard let data = await apiGet(config, path: "/api/v1/consumer-groups") else { return nil }
        if let list = try? JSONDecoder().decode([ConsumerGroupInfo].self, from: data) {
            return list.compactMap(\.lag).reduce(0, +)
        }
        if let response = try? JSONDecoder().decode(ConsumerGroupsResponse.self, from: data) {
            return response.consumerGroups?.compactMap(\.lag).reduce(0, +)
        }
        return nil
    }

    private static func apiGet(_ config: ClusterConfig, path: String) async -> Data? {
        let urlString = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    // MARK: - Status Logic

    private static func determineStatus(
        connected: Bool,
        offlinePartitions: Int,
        underReplicated: Int,
        totalLag: Int64?
    ) -> ClusterStatus {
        guard connected else { return .unknown }
        if offlinePartitions > 0 { return .critical }
        if underReplicated > 0 { return .warning }
        if let lag = totalLag, lag > 10_000 { return .warning }
        return .healthy
    }

    // MARK: - Config Cache

    private static var cachedHealth: [String: ClusterHealth] = [:]

    static func getCachedHealth(for name: String) -> ClusterHealth? {
        cachedHealth[name]
    }

    static func updateCache(_ health: ClusterHealth) {
        cachedHealth[health.clusterName] = health
    }
}
