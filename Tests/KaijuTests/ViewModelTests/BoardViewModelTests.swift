import XCTest
@testable import Kaiju

// Mock API client for ViewModel tests
final class MockJiraAPIClient: JiraAPIClientProtocol, @unchecked Sendable {
    var fetchProjectsCalled = false
    var fetchBoardsCalled = false
    var transitionCalled = false
    var lastTransitionIssueKey: String?
    var lastTransitionId: String?

    func fetchMyself() async throws -> APIUser {
        APIUser(accountId: "user-1", displayName: "Test", avatarUrls: nil, active: true, emailAddress: nil)
    }
    func fetchProjects() async throws -> [APIProject] {
        fetchProjectsCalled = true
        return []
    }
    func fetchRecentProjects() async throws -> [APIProject] { [] }
    func fetchBoards(projectKey: String?) async throws -> [APIBoard] {
        fetchBoardsCalled = true
        return []
    }
    func fetchBoardConfiguration(boardId: Int) async throws -> APIBoardConfiguration {
        APIBoardConfiguration(id: boardId, name: "Test", columnConfig: APIColumnConfig(columns: []), filter: nil)
    }
    func fetchBoardIssues(boardId: Int, startAt: Int, maxResults: Int, fields: String?) async throws -> APIBoardIssueList {
        APIBoardIssueList(maxResults: 50, startAt: 0, total: 0, issues: [])
    }
    func fetchIssue(key: String, fields: String?) async throws -> APIIssue {
        APIIssue(id: "1", key: key, fields: APIIssueFields(
            summary: "Test", description: nil, status: nil, priority: nil,
            issuetype: nil, assignee: nil, reporter: nil, labels: nil,
            comment: nil, attachment: nil, issuelinks: nil, subtasks: nil,
            created: nil, updated: nil, duedate: nil, fixVersions: nil, components: nil,
            customfield_10016: nil, sprint: nil
        ))
    }
    func createIssue(body: Data) async throws -> APIIssue {
        APIIssue(id: "new-1", key: "KAI-99", fields: APIIssueFields(
            summary: "New", description: nil, status: nil, priority: nil,
            issuetype: nil, assignee: nil, reporter: nil, labels: nil,
            comment: nil, attachment: nil, issuelinks: nil, subtasks: nil,
            created: nil, updated: nil, duedate: nil, fixVersions: nil, components: nil,
            customfield_10016: nil, sprint: nil
        ))
    }
    func updateIssue(key: String, body: Data) async throws {}
    func fetchTransitions(issueKey: String) async throws -> [APITransition] { [] }
    func performTransition(issueKey: String, transitionId: String) async throws {
        transitionCalled = true
        lastTransitionIssueKey = issueKey
        lastTransitionId = transitionId
    }
    func fetchComments(issueKey: String, startAt: Int, maxResults: Int) async throws -> APICommentPage {
        APICommentPage(startAt: 0, maxResults: 50, total: 0, comments: [])
    }
    func addComment(issueKey: String, body: ADFDocument) async throws -> APIComment {
        APIComment(id: "c1", author: nil, body: nil, created: nil, updated: nil)
    }
    func searchJQL(jql: String, startAt: Int, maxResults: Int, fields: String?) async throws -> APISearchResult {
        APISearchResult(startAt: 0, maxResults: 50, total: 0, issues: [])
    }
    func fetchPriorities() async throws -> [APIPriority] { [] }
    func fetchStatuses() async throws -> [APIStatus] { [] }
    func fetchIssueTypes() async throws -> [APIIssueType] { [] }
    func fetchAssignableUsers(projectKey: String, query: String?) async throws -> [APIUser] { [] }
    func registerWebhooks(body: Data) async throws -> Data { Data() }
    func refreshWebhooks(webhookIds: [Int]) async throws {}
}

@MainActor
final class BoardViewModelTests: XCTestCase {

    func test_board_vm_initial_state() {
        let store = try! LocalStore()
        let apiClient = MockJiraAPIClient()
        let syncEngine = SyncEngine(store: store, apiClient: apiClient)
        let vm = BoardViewModel(store: store, syncEngine: syncEngine)

        XCTAssertTrue(vm.columns.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.selectedBoardId)
    }
}
