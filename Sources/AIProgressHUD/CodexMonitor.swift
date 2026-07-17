import AppKit
import ApplicationServices
import Foundation

struct CodexThreadRecord: Decodable, Sendable {
    let id: String
    let title: String
    let updatedAt: TimeInterval
    let recencyAt: TimeInterval
    let lastStreamAt: TimeInterval
    let streamStartedAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id, title
        case updatedAt = "updated_at"
        case recencyAt = "recency_at"
        case lastStreamAt = "last_stream_at"
        case streamStartedAt = "stream_started_at"
    }

    func state(now: TimeInterval) -> AIJobState {
        if lastStreamAt > 0, now - lastStreamAt <= 45 { return .streaming }
        if now - identityActivityAt <= 180 { return .thinking }
        return .idle
    }

    var safeTitle: String {
        let oneLine = title
            .replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^\\)]+\\)", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "<image\\b[^>]*>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "path=\"[^\"]+\"", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\r\\n]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return oneLine.isEmpty ? "未命名 Codex 会话" : String(oneLine.prefix(96))
    }
}

@MainActor
final class CodexMonitor {
    private weak var store: JobStore?
    private var timer: Timer?
    private var scanInFlight = false

    init(store: JobStore) { self.store = store }

    func start() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func scan() {
        store?.setAccessibilityTrusted(AXIsProcessTrusted())
        guard !scanInFlight else { return }
        scanInFlight = true
        Task {
            let records = await Self.loadLocalThreads()
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.scanInFlight = false
                self.apply(records)
            }
        }
    }

    private func apply(_ records: [CodexThreadRecord]) {
        let now = Date().timeIntervalSince1970
        var seen: Set<String> = []
        for record in deduplicated(records, now: now) {
            let state = record.state(now: now)
            guard state.isRunning || state == .attention || state == .error else { continue }
            let id = "codex:\(record.id)"
            seen.insert(id)
            store?.upsertCodex(
                threadID: record.id,
                title: record.safeTitle,
                state: state,
                startedAt: Date(timeIntervalSince1970: record.streamStartedAt > 0 ? record.streamStartedAt : record.identityActivityAt),
                lastActivityAt: Date(timeIntervalSince1970: record.sortActivityAt)
            )
        }
        store?.removeMissingCodex(ids: seen)
    }

    private func deduplicated(_ records: [CodexThreadRecord], now: TimeInterval) -> [CodexThreadRecord] {
        var selected: [String: CodexThreadRecord] = [:]
        for record in records {
            let key = record.safeTitle.lowercased()
            guard !key.isEmpty else { continue }
                if let existing = selected[key] {
                    let currentScore = score(record.state(now: now))
                    let existingScore = score(existing.state(now: now))
                if currentScore < existingScore || (currentScore == existingScore && record.sortActivityAt > existing.sortActivityAt) {
                    selected[key] = record
                }
            } else {
                selected[key] = record
            }
        }
        return selected.values
            .sorted {
                (score($0.state(now: now)), -$0.sortActivityAt) <
                    (score($1.state(now: now)), -$1.sortActivityAt)
            }
            .prefix(6)
            .map { $0 }
    }

    private func score(_ state: AIJobState) -> Int {
        switch state {
        case .streaming: 0
        case .thinking: 1
        case .attention, .error: 2
        case .completed: 3
        case .idle, .disconnected: 4
        }
    }

    nonisolated private static func loadLocalThreads() async -> [CodexThreadRecord] {
        await Task.detached(priority: .utility) {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let statePath = home.appendingPathComponent(".codex/state_5.sqlite").path
            let logsPath = home.appendingPathComponent(".codex/logs_2.sqlite").path
            guard FileManager.default.fileExists(atPath: statePath), FileManager.default.fileExists(atPath: logsPath) else { return [] }

            let escapedLogs = logsPath.replacingOccurrences(of: "'", with: "''")
            let query = """
            ATTACH DATABASE 'file:\(escapedLogs)?mode=ro' AS logdb;
            WITH stream_events AS (
                SELECT thread_id, ts
                FROM logdb.logs
                WHERE thread_id IS NOT NULL
                  AND ts >= strftime('%s','now')-7200
                  AND (
                      target='codex_core::stream_events_utils'
                      OR target LIKE 'codex_api::endpoint::responses%'
                      OR target LIKE 'codex_http_client::%'
                      OR target='codex_core::responses_retry'
                  )
            ), stream_gaps AS (
                SELECT thread_id, ts,
                       CASE WHEN ts - LAG(ts) OVER (PARTITION BY thread_id ORDER BY ts) > 30 THEN 1 ELSE 0 END AS starts_new
                FROM stream_events
            ), stream_groups AS (
                SELECT thread_id, ts,
                       SUM(starts_new) OVER (PARTITION BY thread_id ORDER BY ts) AS group_id
                FROM stream_gaps
            ), latest_streams AS (
                SELECT thread_id, MIN(ts) AS stream_started_at, MAX(ts) AS last_stream_at
                FROM stream_groups g
                WHERE group_id = (SELECT MAX(g2.group_id) FROM stream_groups g2 WHERE g2.thread_id=g.thread_id)
                GROUP BY thread_id
            )
            SELECT t.id,
                   substr(replace(replace(t.title, char(10), ' '), char(13), ' '), 1, 160) AS title,
                   t.updated_at,
                   t.recency_at,
                   COALESCE(s.last_stream_at, 0) AS last_stream_at,
                   COALESCE(s.stream_started_at, 0) AS stream_started_at
            FROM threads t
            LEFT JOIN latest_streams s ON s.thread_id=t.id
            WHERE t.archived=0
              AND t.thread_source='user'
              AND max(t.updated_at, t.recency_at) >= strftime('%s','now')-180
            ORDER BY max(t.updated_at, t.recency_at, COALESCE(s.last_stream_at, 0)) DESC LIMIT 12;
            """
            let process = Process()
            let output = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
            process.arguments = ["-readonly", "-json", statePath, query]
            process.standardOutput = output
            process.standardError = Pipe()
            do {
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else { return [] }
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let records = (try? JSONDecoder().decode([CodexThreadRecord].self, from: data)) ?? []
                let displayTitles = Self.loadSessionDisplayTitles(from: home.appendingPathComponent(".codex/session_index.jsonl").path)
                return records.map { record in
                    guard let title = displayTitles[record.id], !title.isEmpty else { return record }
                    return CodexThreadRecord(
                        id: record.id,
                        title: title,
                        updatedAt: record.updatedAt,
                        recencyAt: record.recencyAt,
                        lastStreamAt: record.lastStreamAt,
                        streamStartedAt: record.streamStartedAt
                    )
                }
            } catch { return [] }
        }.value
    }

    nonisolated private static func loadSessionDisplayTitles(from path: String) -> [String: String] {
        guard let data = FileManager.default.contents(atPath: path),
              let text = String(data: data, encoding: .utf8) else { return [:] }
        var titles: [String: (name: String, updatedAt: String)] = [:]
        for line in text.split(separator: "\n") {
            guard let lineData = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let id = object["id"] as? String,
                  let name = object["thread_name"] as? String,
                  let updatedAt = object["updated_at"] as? String else { continue }
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanName.isEmpty else { continue }
            if let existing = titles[id], existing.updatedAt > updatedAt { continue }
            titles[id] = (cleanName, updatedAt)
        }
        return titles.mapValues(\.name)
    }
}

private extension CodexThreadRecord {
    var identityActivityAt: TimeInterval { max(updatedAt, recencyAt) }
    var sortActivityAt: TimeInterval { max(identityActivityAt, lastStreamAt) }
}
