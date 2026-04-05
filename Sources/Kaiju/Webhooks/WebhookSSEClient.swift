import Foundation
import os

/// Server-Sent Events (SSE) client for receiving webhook events from the relay server
actor WebhookSSEClient {
    private let logger = KaijuLogger.webhook
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var delegate: SSESessionDelegate?

    private(set) var isConnected: Bool = false
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 10

    /// Callback for received events
    var onEvent: (@Sendable (String, String) -> Void)?  // (event type, data)
    /// Callback for connection state changes
    var onConnectionStateChanged: (@Sendable (Bool) -> Void)?

    let relayURL: String

    init(relayURL: String) {
        self.relayURL = relayURL
    }

    /// Connect to the SSE stream
    func connect() {
        guard !isConnected else { return }

        guard let url = URL(string: relayURL) else {
            logger.error("Invalid relay URL: \(self.relayURL)")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = TimeInterval.infinity

        let delegate = SSESessionDelegate { [weak self] eventType, data in
            guard let self = self else { return }
            Task {
                await self.handleEvent(eventType: eventType, data: data)
            }
        } onDisconnect: { [weak self] in
            guard let self = self else { return }
            Task {
                await self.handleDisconnect()
            }
        }

        self.delegate = delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval.infinity
        config.timeoutIntervalForResource = TimeInterval.infinity
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        task = session?.dataTask(with: request)
        task?.resume()

        isConnected = true
        reconnectAttempts = 0
        onConnectionStateChanged?(true)
        logger.info("SSE connected to \(self.relayURL)")
    }

    /// Disconnect from the SSE stream
    func disconnect() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        delegate = nil
        isConnected = false
        onConnectionStateChanged?(false)
        logger.info("SSE disconnected")
    }

    private func handleEvent(eventType: String, data: String) {
        onEvent?(eventType, data)
    }

    private func handleDisconnect() {
        isConnected = false
        onConnectionStateChanged?(false)
        logger.warning("SSE connection lost. Attempting reconnect...")

        Task {
            await reconnect()
        }
    }

    private func reconnect() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            logger.error("Max reconnect attempts reached. Giving up.")
            return
        }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0)
        let jitter = Double.random(in: 0...1)

        logger.info("Reconnecting in \(delay + jitter)s (attempt \(self.reconnectAttempts))")

        try? await Task.sleep(nanoseconds: UInt64((delay + jitter) * 1_000_000_000))

        connect()
    }
}

/// URLSession delegate that parses SSE stream data
final class SSESessionDelegate: NSObject, URLSessionDataDelegate, Sendable {
    private let onEvent: @Sendable (String, String) -> Void
    private let onDisconnect: @Sendable () -> Void

    init(
        onEvent: @escaping @Sendable (String, String) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) {
        self.onEvent = onEvent
        self.onDisconnect = onDisconnect
    }

    nonisolated func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        parseSSE(text)
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        onDisconnect()
    }

    private nonisolated func parseSSE(_ text: String) {
        var eventType = "message"
        var dataLines: [String] = []

        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces))
            } else if line.isEmpty && !dataLines.isEmpty {
                // Empty line marks end of event
                let data = dataLines.joined(separator: "\n")
                onEvent(eventType, data)
                eventType = "message"
                dataLines = []
            }
        }

        // Handle case where there's no trailing newline
        if !dataLines.isEmpty {
            let data = dataLines.joined(separator: "\n")
            onEvent(eventType, data)
        }
    }
}
