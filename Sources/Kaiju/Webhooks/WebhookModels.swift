import Foundation

/// Events received from Jira webhooks via the relay server
enum WebhookEventType: String, Codable, Sendable {
    case issueCreated = "jira:issue_created"
    case issueUpdated = "jira:issue_updated"
    case issueDeleted = "jira:issue_deleted"
    case commentCreated = "comment_created"
    case commentUpdated = "comment_updated"
    case commentDeleted = "comment_deleted"
}

/// A parsed webhook event from the SSE stream
struct WebhookEvent: Codable, Sendable {
    let webhookEvent: String
    let issueKey: String?
    let issue: WebhookIssueRef?
    let comment: WebhookCommentRef?
    let user: WebhookUserRef?
    let timestamp: Int64?
}

struct WebhookIssueRef: Codable, Sendable {
    let id: String?
    let key: String?
    let fields: WebhookIssueFields?
}

struct WebhookIssueFields: Codable, Sendable {
    let summary: String?
    let status: WebhookStatusRef?
    let assignee: WebhookUserRef?
}

struct WebhookStatusRef: Codable, Sendable {
    let name: String?
}

struct WebhookCommentRef: Codable, Sendable {
    let id: String?
    let body: String?
}

struct WebhookUserRef: Codable, Sendable {
    let accountId: String?
    let displayName: String?
    let avatarUrls: [String: String]?
}

/// Registration request body for Jira dynamic webhooks
struct WebhookRegistrationRequest: Codable, Sendable {
    let url: String
    let webhooks: [WebhookDefinition]
}

struct WebhookDefinition: Codable, Sendable {
    let events: [String]
    let jqlFilter: String?
    let fieldIdsFilter: [String]?
}

/// Response from webhook registration
struct WebhookRegistrationResponse: Codable, Sendable {
    let webhookRegistrationResult: [WebhookRegistrationResultItem]?
}

struct WebhookRegistrationResultItem: Codable, Sendable {
    let createdWebhookId: Int?
    let errors: [String]?
}
