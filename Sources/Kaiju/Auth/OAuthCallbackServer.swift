import Foundation
import Network
import os

/// Lightweight HTTP server that listens on 127.0.0.1:21456 for the OAuth callback
actor OAuthCallbackServer {
    private let logger = KaijuLogger.auth
    private var listener: NWListener?
    private var continuation: CheckedContinuation<OAuthCallbackResult, Error>?

    let port: UInt16

    init(port: UInt16 = 21456) {
        self.port = port
    }

    struct OAuthCallbackResult: Sendable {
        let code: String
        let state: String
    }

    enum CallbackError: Error, Sendable {
        case serverStartFailed(Error)
        case missingParameters
        case stateMismatch(expected: String, received: String)
        case cancelled
    }

    /// Start listening and wait for the OAuth callback
    /// - Parameter expectedState: The state parameter to validate against
    /// - Returns: The authorization code and state from the callback
    func waitForCallback(expectedState: String) async throws -> OAuthCallbackResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            startListener(expectedState: expectedState)
        }
    }

    private func startListener(expectedState: String) {
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)

            listener?.newConnectionHandler = { [weak self] connection in
                Task { [weak self] in
                    await self?.handleConnection(connection, expectedState: expectedState)
                }
            }

            listener?.stateUpdateHandler = { [weak self] state in
                Task { [weak self] in
                    await self?.handleListenerState(state)
                }
            }

            listener?.start(queue: .global())
            logger.info("OAuth callback server started on port \(self.port)")
        } catch {
            continuation?.resume(throwing: CallbackError.serverStartFailed(error))
            continuation = nil
        }
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .failed(let error):
            logger.error("Listener failed: \(error.localizedDescription)")
            continuation?.resume(throwing: CallbackError.serverStartFailed(error))
            continuation = nil
        case .cancelled:
            break
        default:
            break
        }
    }

    private func handleConnection(_ connection: NWConnection, expectedState: String) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            Task { [weak self] in
                await self?.processRequest(data: data, connection: connection, expectedState: expectedState)
            }
        }
    }

    private func processRequest(data: Data?, connection: NWConnection, expectedState: String) {
        defer {
            stop()
        }

        guard let data = data,
              let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            continuation?.resume(throwing: CallbackError.missingParameters)
            continuation = nil
            return
        }

        // Parse the GET request to extract query parameters
        guard let queryString = parseQueryString(from: requestString) else {
            sendResponse(connection: connection, statusCode: 400, body: "Missing query parameters")
            continuation?.resume(throwing: CallbackError.missingParameters)
            continuation = nil
            return
        }

        let params = parseQueryParams(queryString)

        guard let code = params["code"], let state = params["state"] else {
            sendResponse(connection: connection, statusCode: 400, body: "Missing code or state parameter")
            continuation?.resume(throwing: CallbackError.missingParameters)
            continuation = nil
            return
        }

        guard state == expectedState else {
            sendResponse(connection: connection, statusCode: 400, body: "State mismatch")
            continuation?.resume(throwing: CallbackError.stateMismatch(expected: expectedState, received: state))
            continuation = nil
            return
        }

        let html = """
        <html><body style="font-family:-apple-system;text-align:center;padding:60px;">
        <h1>✓ Signed in to Kaiju</h1>
        <p>You can close this tab and return to the app.</p>
        </body></html>
        """
        sendResponse(connection: connection, statusCode: 200, body: html, contentType: "text/html")

        let result = OAuthCallbackResult(code: code, state: state)
        continuation?.resume(returning: result)
        continuation = nil
    }

    private func parseQueryString(from request: String) -> String? {
        // Parse "GET /oauth/callback?code=xxx&state=yyy HTTP/1.1"
        guard let firstLine = request.split(separator: "\r\n").first ?? request.split(separator: "\n").first else {
            return nil
        }
        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        let path = String(parts[1])
        guard let questionMark = path.firstIndex(of: "?") else { return nil }
        return String(path[path.index(after: questionMark)...])
    }

    private func parseQueryParams(_ query: String) -> [String: String] {
        var params: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                let key = String(kv[0]).removingPercentEncoding ?? String(kv[0])
                let value = String(kv[1]).removingPercentEncoding ?? String(kv[1])
                params[key] = value
            }
        }
        return params
    }

    private func sendResponse(
        connection: NWConnection,
        statusCode: Int,
        body: String,
        contentType: String = "text/plain"
    ) {
        let statusText = statusCode == 200 ? "OK" : "Bad Request"
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """
        let responseData = Data(response.utf8)
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }
}
