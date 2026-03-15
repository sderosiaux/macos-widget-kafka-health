# macos-widget-kafka-health

A native macOS desktop widget for monitoring Kafka cluster health across environments. LittleSnitch-inspired: compact, always-visible, color-coded.

Connects to Conduktor Console API to show cluster status for dev, staging, and production.

## Planned features

- Color-coded status per cluster/environment (green/yellow/red)
- Key metrics: consumer group lag, broker count, under-replicated partitions, throughput
- Sparklines for throughput trends
- Red alerts for anomalies
- Click to open Conduktor Console
- Auth via Conduktor API token (keychain or dotfile)
- Same SwiftUI+AppKit floating window pattern as [linkedin-desktop-widget](https://github.com/sderosiaux/linkedin-desktop-widget)

## Prerequisites

- macOS 14+
- Swift 5.9+
- Conduktor Console API access + token

## Status

Scaffolded. Not yet implemented.

## License

MIT
