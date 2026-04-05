import Foundation
import os

/// Rate limit information parsed from Jira API response headers
struct RateLimitInfo: Sendable {
    let limit: Int?
    let remaining: Int?
    let reset: Date?
    let retryAfter: TimeInterval?
    let rateLimitType: RateLimitType?

    enum RateLimitType: String, Sendable {
        case burst = "jira-burst-based"
        case quota = "jira-quota-global-based"
    }

    /// Parse rate limit headers from an HTTP response
    static func from(response: HTTPURLResponse) -> RateLimitInfo {
        let limit = response.value(forHTTPHeaderField: "X-RateLimit-Limit").flatMap(Int.init)
        let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining").flatMap(Int.init)
        let resetTimestamp = response.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap(TimeInterval.init)
        let reset = resetTimestamp.map { Date(timeIntervalSince1970: $0) }
        let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
        let rateLimitType = response.value(forHTTPHeaderField: "X-RateLimit-Type")
            .flatMap(RateLimitType.init(rawValue:))

        return RateLimitInfo(
            limit: limit,
            remaining: remaining,
            reset: reset,
            retryAfter: retryAfter,
            rateLimitType: rateLimitType
        )
    }
}

/// Errors surfaced by the rate limiter
enum RateLimitError: Error, Sendable {
    case rateLimited(retryAfter: TimeInterval)
    case quotaExhausted(retryAfter: TimeInterval)
    case maxRetriesExceeded(lastStatusCode: Int)
}

/// Middleware that handles rate limiting, retries with exponential backoff,
/// and parses rate limit headers from Jira API responses
actor RateLimiter {
    private let logger = Logger(subsystem: "com.kaiju.app", category: "RateLimiter")

    /// Maximum number of retries before surfacing error
    let maxRetries: Int

    /// Maximum backoff interval in seconds
    let maxBackoff: TimeInterval

    /// Current rate limit state
    private(set) var lastRateLimitInfo: RateLimitInfo?

    init(maxRetries: Int = 5, maxBackoff: TimeInterval = 60) {
        self.maxRetries = maxRetries
        self.maxBackoff = maxBackoff
    }

    /// Execute an HTTP request with rate limit handling and retries
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - session: URLSession to use
    /// - Returns: Tuple of data and HTTP response
    func execute(
        request: URLRequest,
        session: URLSession = .shared
    ) async throws -> (Data, HTTPURLResponse) {
        var currentRetry = 0

        while true {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            // Parse and store rate limit headers from every response
            let rateLimitInfo = RateLimitInfo.from(response: httpResponse)
            lastRateLimitInfo = rateLimitInfo

            // Success
            if (200...299).contains(httpResponse.statusCode) {
                return (data, httpResponse)
            }

            // Rate limited
            if httpResponse.statusCode == 429 {
                currentRetry += 1

                if currentRetry > maxRetries {
                    throw RateLimitError.maxRetriesExceeded(lastStatusCode: 429)
                }

                let delay = calculateDelay(
                    retry: currentRetry,
                    rateLimitInfo: rateLimitInfo
                )

                logger.warning("Rate limited (429). Retry \(currentRetry)/\(self.maxRetries) after \(delay)s")

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }

            // Other errors — don't retry
            return (data, httpResponse)
        }
    }

    /// Calculate delay for a retry attempt based on rate limit type
    func calculateDelay(retry: Int, rateLimitInfo: RateLimitInfo) -> TimeInterval {
        // If we have a Retry-After header, use it as the base
        if let retryAfter = rateLimitInfo.retryAfter {
            switch rateLimitInfo.rateLimitType {
            case .quota:
                // Quota-based: back off significantly (minimum 60s)
                return max(retryAfter, 60)
            case .burst:
                // Burst-based: short jitter (0.5-2s range)
                let jitter = Double.random(in: 0.5...2.0)
                return jitter
            case nil:
                return retryAfter
            }
        }

        // Exponential backoff: 1s, 2s, 4s, 8s, ... capped at maxBackoff
        let exponential = pow(2.0, Double(retry - 1))
        let jitter = Double.random(in: 0.0...0.5)
        return min(exponential + jitter, maxBackoff)
    }
}
