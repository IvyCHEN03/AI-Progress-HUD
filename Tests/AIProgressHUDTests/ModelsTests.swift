import XCTest
@testable import AIProgressHUD

final class ModelsTests: XCTestCase {
    func testRunningStates() {
        XCTAssertTrue(AIJobState.thinking.isRunning)
        XCTAssertTrue(AIJobState.streaming.isRunning)
        XCTAssertFalse(AIJobState.completed.isRunning)
    }

    func testBrowserEventDecoding() throws {
        let data = #"{"token":"pair","provider":"chatgpt","tabId":12,"state":"thinking"}"#.data(using: .utf8)!
        let event = try JSONDecoder().decode(BrowserEvent.self, from: data)
        XCTAssertEqual(event.provider, .chatgpt)
        XCTAssertEqual(event.tabId, 12)
        XCTAssertEqual(event.state, .thinking)
    }

    func testCodexThreadsAreSeparatedAndSanitized() {
        let now = Date().timeIntervalSince1970
        let first = CodexThreadRecord(id: "thread-111111", title: "任务一\n第二行", updatedAt: now, lastStreamAt: now, streamStartedAt: now - 5)
        let second = CodexThreadRecord(id: "thread-222222", title: "任务二", updatedAt: now, lastStreamAt: now, streamStartedAt: now - 5)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(first.safeTitle, "任务一 第二行")
        XCTAssertEqual(first.state(now: now), .streaming)
    }

    func testCodexRecentResponseBecomesCompleted() {
        let now = Date().timeIntervalSince1970
        let record = CodexThreadRecord(id: "thread", title: "任务", updatedAt: now - 20, lastStreamAt: now - 20, streamStartedAt: now - 40)
        XCTAssertEqual(record.state(now: now), .completed)
    }

    func testTaskSourceBadgesStayHumanReadable() {
        let now = Date()
        let codex = AIJobSnapshot(
            id: "codex:019f504a-9f37-71b3-a321-6d904c724fd3",
            provider: .codex, pageTitle: "Task", state: .streaming,
            startedAt: now, lastChangedAt: now, lastHeartbeatAt: now,
            needsAttention: false, source: "codex"
        )
        var browser = codex
        browser.source = "browser"
        XCTAssertEqual(codex.sourceBadge, "")
        XCTAssertEqual(browser.sourceBadge, "WEB")
    }
}
