import XCTest
@testable import Kaiju

final class RateLimiterTests: XCTestCase {

    func test_rate_limit_headers_parsed_from_response() {
        let url = URL(string: "https://api.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "X-RateLimit-Limit": "100",
                "X-RateLimit-Remaining": "50",
                "X-RateLimit-Reset": "1700000000",
                "Retry-After": "5",
            ]
        )!

        let info = RateLimitInfo.from(response: response)

        XCTAssertEqual(info.limit, 100)
        XCTAssertEqual(info.remaining, 50)
        XCTAssertNotNil(info.reset)
        XCTAssertEqual(info.retryAfter, 5)
    }

    func test_exponential_backoff_caps_at_max() async {
        let limiter = RateLimiter(maxRetries: 5, maxBackoff: 60)

        // Retry 7 should be capped at 60
        let info = RateLimitInfo(limit: nil, remaining: nil, reset: nil, retryAfter: nil, rateLimitType: nil)
        let delay = await limiter.calculateDelay(retry: 7, rateLimitInfo: info)

        XCTAssertLessThanOrEqual(delay, 60.5)  // 60 + possible jitter
    }

    func test_burst_rate_limit_uses_short_jitter() async {
        let limiter = RateLimiter(maxRetries: 5, maxBackoff: 60)

        let info = RateLimitInfo(
            limit: nil, remaining: nil, reset: nil,
            retryAfter: 1,
            rateLimitType: .burst
        )
        let delay = await limiter.calculateDelay(retry: 1, rateLimitInfo: info)

        // Burst should use jitter between 0.5 and 2.0
        XCTAssertGreaterThanOrEqual(delay, 0.5)
        XCTAssertLessThanOrEqual(delay, 2.0)
    }

    func test_quota_rate_limit_backs_off_significantly() async {
        let limiter = RateLimiter(maxRetries: 5, maxBackoff: 120)

        let info = RateLimitInfo(
            limit: nil, remaining: nil, reset: nil,
            retryAfter: 30,
            rateLimitType: .quota
        )
        let delay = await limiter.calculateDelay(retry: 1, rateLimitInfo: info)

        // Quota should back off at least 60 seconds
        XCTAssertGreaterThanOrEqual(delay, 60)
    }
}
