import XCTest
@testable import Kaiju

final class SSEParsingTests: XCTestCase {

    func test_webhook_event_decodes_issue_updated() throws {
        let json = """
        {"webhookEvent":"jira:issue_updated","issueKey":"KAI-1","issue":{"id":"10001","key":"KAI-1","fields":{"summary":"Updated issue","status":{"name":"In Progress"}}},"user":{"accountId":"user-123","displayName":"Alice"},"timestamp":1700000000}
        """
        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(WebhookEvent.self, from: data)

        XCTAssertEqual(event.webhookEvent, "jira:issue_updated")
        XCTAssertEqual(event.issueKey, "KAI-1")
        XCTAssertEqual(event.issue?.key, "KAI-1")
        XCTAssertEqual(event.issue?.fields?.summary, "Updated issue")
        XCTAssertEqual(event.issue?.fields?.status?.name, "In Progress")
        XCTAssertEqual(event.user?.displayName, "Alice")
    }

    func test_webhook_event_type_enum() {
        XCTAssertEqual(WebhookEventType(rawValue: "jira:issue_created"), .issueCreated)
        XCTAssertEqual(WebhookEventType(rawValue: "jira:issue_updated"), .issueUpdated)
        XCTAssertEqual(WebhookEventType(rawValue: "jira:issue_deleted"), .issueDeleted)
        XCTAssertEqual(WebhookEventType(rawValue: "comment_created"), .commentCreated)
        XCTAssertEqual(WebhookEventType(rawValue: "comment_updated"), .commentUpdated)
        XCTAssertEqual(WebhookEventType(rawValue: "comment_deleted"), .commentDeleted)
        XCTAssertNil(WebhookEventType(rawValue: "unknown_event"))
    }

    func test_webhook_registration_request_encodes() throws {
        let request = WebhookRegistrationRequest(
            url: "https://relay.example.com/webhook/cloud-123",
            webhooks: [
                WebhookDefinition(
                    events: ["jira:issue_created", "jira:issue_updated"],
                    jqlFilter: "project = KAI",
                    fieldIdsFilter: ["summary", "status"]
                )
            ]
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["url"] as? String, "https://relay.example.com/webhook/cloud-123")
        let webhooks = json["webhooks"] as? [[String: Any]]
        XCTAssertEqual(webhooks?.count, 1)
        XCTAssertEqual(webhooks?[0]["jqlFilter"] as? String, "project = KAI")
    }
}
