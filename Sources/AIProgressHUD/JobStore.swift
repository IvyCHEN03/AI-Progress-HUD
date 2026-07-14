import AppKit
import ApplicationServices
import Foundation
import SwiftUI

@MainActor
final class JobStore: ObservableObject {
    @Published private(set) var jobs: [AIJobSnapshot] = []
    @Published var settings: HUDSettings { didSet { saveSettings() } }
    @Published private(set) var serverOnline = false
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()
    @Published private(set) var accessibilityPreviouslyGranted = UserDefaults.standard.object(forKey: "hud.accessibilityLastGrantedAt") != nil
    @Published private(set) var browserLastSeenAt: Date?
    @Published private(set) var browserBridgeLastSeenAt: Date?
    @Published private(set) var codexLastSeenAt: Date?
    @Published private(set) var desktopLastSeenAt: Date?
    @Published var demoMode = false
    @Published var showSettings = false

    let pairingToken: String
    private var demoReference = Date()
    private var staleTimer: Timer?
    var activateBrowserTab: ((Int, Int?) -> Void)?
    var settingsChanged: ((HUDSettings) -> Void)?
    var onRequestSettings: (() -> Void)?
    var onRequestQuit: (() -> Void)?

    var presentedJobs: [AIJobSnapshot] {
        demoMode ? Self.demoJobs(reference: demoReference) : jobs
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "hud.settings"),
           let value = try? JSONDecoder().decode(HUDSettings.self, from: data) {
            settings = value
        } else {
            settings = HUDSettings()
        }
        if let saved = defaults.string(forKey: "hud.pairingToken"), !saved.isEmpty {
            pairingToken = saved
        } else {
            let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            pairingToken = token
            defaults.set(token, forKey: "hud.pairingToken")
        }
        staleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.markStaleJobs() }
        }
    }

    func setServerOnline(_ online: Bool) { serverOnline = online }

    func setAccessibilityTrusted(_ trusted: Bool) {
        accessibilityTrusted = trusted
        if trusted {
            accessibilityPreviouslyGranted = true
            UserDefaults.standard.set(Date(), forKey: "hud.accessibilityLastGrantedAt")
        }
    }

    func refreshAccessibilityStatus() {
        setAccessibilityTrusted(AXIsProcessTrusted())
    }
    func markBrowserBridgeSeen() { browserBridgeLastSeenAt = Date() }

    var browserReporting: Bool {
        let lastSeen = [browserBridgeLastSeenAt, browserLastSeenAt].compactMap { $0 }.max()
        guard let lastSeen else { return false }
        return Date().timeIntervalSince(lastSeen) < 35
    }

    var codexReporting: Bool {
        guard let codexLastSeenAt else { return false }
        return Date().timeIntervalSince(codexLastSeenAt) < 15
    }

    func receive(_ event: BrowserEvent) {
        guard event.token == pairingToken else { return }
        browserLastSeenAt = Date()
        if event.type == "closed", let tabId = event.tabId {
            jobs.removeAll { $0.tabId == tabId && $0.source == "browser" }
            return
        }
        guard let provider = event.provider, let tabId = event.tabId, let state = event.state else { return }
        let now = Date()
        let id = "browser:\(tabId)"
        let previous = jobs.first { $0.id == id }
        // Idle heartbeats mean that this tab has no active generation. Do not
        // turn every open ChatGPT home page into a misleading “等待中” row.
        if state == .idle {
            if previous?.state == .completed || previous?.state == .attention || previous?.state == .error { return }
            jobs.removeAll { $0.id == id }
            return
        }
        let snapshot = AIJobSnapshot(
            id: id,
            provider: provider,
            tabId: tabId,
            windowId: event.windowId,
            pageTitle: provider.conversationTitle(from: event.pageTitle ?? "", fallbackID: String(tabId)),
            state: state,
            startedAt: event.startedAt ?? (state.isRunning ? previous?.startedAt ?? now : previous?.startedAt),
            lastChangedAt: event.lastChangedAt ?? (previous?.state == state ? previous?.lastChangedAt ?? now : now),
            lastHeartbeatAt: now,
            needsAttention: event.needsAttention ?? (state == .attention),
            source: "browser"
        )
        upsert(snapshot)
    }

    func upsertCodex(threadID: String, title: String, state: AIJobState, startedAt: Date?, lastActivityAt: Date) {
        let now = Date()
        codexLastSeenAt = now
        let id = "codex:\(threadID)"
        let old = jobs.first { $0.id == id }
        upsert(AIJobSnapshot(
            id: id, provider: .codex, pageTitle: AIProvider.codex.conversationTitle(from: title, fallbackID: String(threadID.suffix(6)).uppercased()), state: state,
            startedAt: state.isRunning ? old?.startedAt ?? startedAt ?? now : old?.startedAt ?? startedAt,
            lastChangedAt: old?.state == state ? old?.lastChangedAt ?? lastActivityAt : lastActivityAt,
            lastHeartbeatAt: now, needsAttention: state == .attention,
            source: "codex"
        ))
    }

    func upsertDesktop(provider: AIProvider, bundleID: String, windowKey: String, title: String, detectedState: AIJobState) {
        let now = Date()
        desktopLastSeenAt = now
        let id = "desktop:\(bundleID):\(windowKey)"
        let old = jobs.first { $0.id == id }
        if detectedState == .idle {
            // Accessibility labels can disappear for a frame while a desktop
            // answer is still running. Hide unclassified idle windows instead
            // of falsely promoting them to completed.
            jobs.removeAll { $0.id == id }
            return
        }
        upsert(AIJobSnapshot(
            id: id, provider: provider, pageTitle: provider.conversationTitle(from: title), state: detectedState,
            startedAt: detectedState.isRunning ? old?.startedAt ?? now : old?.startedAt,
            lastChangedAt: old?.state == detectedState ? old?.lastChangedAt ?? now : now,
            lastHeartbeatAt: now, needsAttention: detectedState == .attention,
            source: "desktop:\(bundleID)"
        ))
    }

    func removeMissingDesktop(ids: Set<String>) {
        jobs.removeAll { $0.source.hasPrefix("desktop:") && !ids.contains($0.id) }
    }

    func removeMissingCodex(ids: Set<String>) {
        jobs.removeAll { $0.source == "codex" && !ids.contains($0.id) }
    }

    func setManualState(_ job: AIJobSnapshot, state: AIJobState) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
        let old = jobs[index]
        jobs[index].state = state
        jobs[index].needsAttention = state == .attention
        jobs[index].lastChangedAt = Date()
        if state.isRunning && !old.state.isRunning { jobs[index].startedAt = Date() }
    }

    func open(_ job: AIJobSnapshot) {
        if job.source.hasPrefix("demo:") { return }
        if job.source.hasPrefix("desktop:"), !accessibilityTrusted {
            requestSettings()
            return
        }
        if let tabId = job.tabId { activateBrowserTab?(tabId, job.windowId) }
        else if job.provider == .codex {
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex").first?.activate()
        } else if job.source.hasPrefix("desktop:") {
            let bundleID = String(job.source.dropFirst("desktop:".count))
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.activate()
        }
        if job.state == .completed {
            jobs.removeAll { $0.id == job.id }
        }
    }

    func clearData() { jobs.removeAll() }

    func toggleDemoMode() {
        if !demoMode { demoReference = Date() }
        demoMode.toggle()
    }

    func requestSettings() {
        showSettings = true
        onRequestSettings?()
    }

    func requestQuit() {
        onRequestQuit?()
    }

    private func upsert(_ value: AIJobSnapshot) {
        if let index = jobs.firstIndex(where: { $0.id == value.id }) { jobs[index] = value }
        else { jobs.append(value) }
        jobs.sort { (priority($0.state), $0.provider.rawValue, $0.pageTitle) < (priority($1.state), $1.provider.rawValue, $1.pageTitle) }
    }

    private func priority(_ state: AIJobState) -> Int {
        switch state {
        case .attention, .error: 0
        case .thinking, .streaming: 1
        case .completed: 2
        case .idle: 3
        case .disconnected: 4
        }
    }

    private func markStaleJobs() {
        let cutoff = Date().addingTimeInterval(-18)
        for index in jobs.indices where jobs[index].source == "browser" && jobs[index].lastHeartbeatAt < cutoff {
            jobs[index].state = .disconnected
        }
        objectWillChange.send()
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: "hud.settings") }
        settingsChanged?(settings)
    }

    private static func demoJobs(reference now: Date) -> [AIJobSnapshot] {
        func job(_ id: String, _ provider: AIProvider, _ title: String, _ state: AIJobState, _ seconds: TimeInterval, _ source: String) -> AIJobSnapshot {
            AIJobSnapshot(
                id: id, provider: provider, pageTitle: title, state: state,
                startedAt: state.isRunning ? now.addingTimeInterval(-seconds) : nil,
                lastChangedAt: now.addingTimeInterval(-min(seconds, 30)),
                lastHeartbeatAt: now, needsAttention: state == .attention, source: source
            )
        }
        return [
            job("demo:web:chatgpt", .chatgpt, "Market landscape synthesis", .streaming, 138, "demo:web"),
            job("demo:app:claude", .claude, "World models investment memo", .thinking, 47, "demo:app"),
            job("demo:codex:4FD3A1", .codex, "Ship provider adapters and tests", .completed, 0, "demo:codex"),
            job("demo:codex:91BC20", .codex, "Polish release onboarding", .streaming, 76, "demo:codex"),
            job("demo:web:deepseek", .deepseek, "Comparable transaction research", .completed, 0, "demo:web"),
            job("demo:web:yuanbao", .yuanbao, "China market company mapping", .attention, 0, "demo:web")
        ]
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
