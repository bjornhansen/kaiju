# Kaiju - Native macOS Jira Client

## Build & Test

```bash
swift build          # Build the package
swift test           # Run all 49 tests
```

## Project Structure

- **Swift Package** (swift-tools-version 5.9, macOS 14+)
- **Dependencies**: GRDB.swift (SQLite), KeychainAccess (secure storage)
- **Target**: `Kaiju` executable target (tests can depend on it since Swift 5.4)
- `Sources/Kaiju/` — main source code
- `Tests/KaijuTests/` — test suite

### Key modules

| Directory | Purpose |
|-----------|---------|
| `App/` | SwiftUI `@main` app entry point + AppState |
| `Auth/` | OAuth 2.0 (3LO) with Atlassian |
| `API/` | JiraAPIClient, endpoints, rate limiter, API models |
| `Store/` | GRDB-backed local SQLite store, schema, migrations |
| `Sync/` | SyncEngine actor, conflict resolver, queue, scheduler |
| `Webhooks/` | SSE client, event handler, registrar |
| `Notifications/` | macOS native notification bridge, inbox store |
| `ViewModels/` | Observable view models (Board, Issue, Search, etc.) |
| `Views/` | SwiftUI views organized by feature |
| `Utilities/` | KeychainHelper, DateFormatters, Logger |
| `ADF/` | Atlassian Document Format parser/renderer |

## Conventions

- Protocol-based dependency injection (e.g. `JiraAPIClientProtocol`, `LocalStoreProtocol`, `KeychainHelperProtocol`) for testability
- `SyncEngine` is an `actor` — ViewModels never call the network directly; they request syncs through the engine
- Optimistic UI updates with server reconciliation
- `@Observable` for view models and state management
- `Sendable` conformance throughout; use `@preconcurrency import` for non-Sendable third-party types
- XCTest-based tests; avoid `async` calls inside `XCTAssert*` autoclosures (extract to a `let` first)
