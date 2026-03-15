import Foundation
import SwiftUI

// MARK: - Configuration

struct ClusterConfig: Codable, Identifiable {
    var id: String { name }
    let name: String
    let baseUrl: String
    let apiToken: String
    let environment: ClusterEnvironment
}

enum ClusterEnvironment: String, Codable {
    case dev
    case staging
    case prod
}

struct WidgetConfig: Codable {
    let clusters: [ClusterConfig]
    let refreshInterval: Int?

    var interval: Int { refreshInterval ?? 60 }

    static let configDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/kafka-health-widget")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let configFile: URL = configDir.appendingPathComponent("config.json")

    static func load() -> Self? {
        let url = configFile
        guard FileManager.default.fileExists(atPath: url.path) else {
            createSampleConfig()
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Self.self, from: data)
    }

    private static func createSampleConfig() {
        let sample = Self(
            clusters: [
                ClusterConfig(
                    name: "Local Dev",
                    baseUrl: "http://localhost:8080",
                    apiToken: "your-token-here",
                    environment: .dev
                ),
            ],
            refreshInterval: 60
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(sample) else { return }
        try? data.write(to: configFile)
        NSLog("[KafkaHealthWidget] Sample config created at \(configFile.path)")
        NSLog("[KafkaHealthWidget] Edit the config with your Conduktor Console credentials")
    }
}

// MARK: - Health Data

enum ClusterStatus: String, Codable {
    case healthy
    case warning
    case critical
    case unknown

    var color: Color {
        switch self {
        case .healthy: .green
        case .warning: .orange
        case .critical: .red
        case .unknown: .gray
        }
    }

    var label: String {
        switch self {
        case .healthy: "Healthy"
        case .warning: "Warning"
        case .critical: "Critical"
        case .unknown: "Unknown"
        }
    }

    var severity: Int {
        switch self {
        case .unknown: 0
        case .healthy: 1
        case .warning: 2
        case .critical: 3
        }
    }
}

struct ClusterHealth: Identifiable {
    var id: String { clusterName }
    let clusterName: String
    let environment: ClusterEnvironment
    let baseUrl: String
    let status: ClusterStatus
    let brokerCount: Int
    let topicCount: Int
    let consumerGroupCount: Int
    let underReplicatedPartitions: Int
    let offlinePartitions: Int
    let totalLag: Int64?
    let lastChecked: Date
}

extension ClusterEnvironment {
    var badgeColor: Color {
        switch self {
        case .prod: .blue
        case .staging: .green
        case .dev: .gray
        }
    }
}
