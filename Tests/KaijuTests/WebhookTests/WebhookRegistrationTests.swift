import XCTest
@testable import Kaiju

final class WebhookRegistrationTests: XCTestCase {

    func test_webhook_registration_sends_correct_events() throws {
        let request = WebhookRegistrationRequest(
            url: "https://relay.example.com/webhook/cloud-id",
            webhooks: [
                WebhookDefinition(
                    events: [
                        "jira:issue_created",
                        "jira:issue_updated",
                        "jira:issue_deleted",
                        "comment_created",
                        "comment_updated",
                        "comment_deleted",
                    ],
                    jqlFilter: "project IN (KAI, EXP)",
                    fieldIdsFilter: ["summary", "status", "assignee", "priority", "comment"]
                )
            ]
        )

        XCTAssertEqual(request.webhooks[0].events.count, 6)
        XCTAssertTrue(request.webhooks[0].events.contains("jira:issue_created"))
        XCTAssertTrue(request.webhooks[0].events.contains("comment_created"))
        XCTAssertEqual(request.webhooks[0].jqlFilter, "project IN (KAI, EXP)")
        XCTAssertEqual(request.webhooks[0].fieldIdsFilter?.count, 5)
    }
}
