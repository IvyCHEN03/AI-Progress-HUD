import Foundation

enum AIJobState: String, Codable, CaseIterable, Sendable {
    case idle, thinking, streaming, completed, attention, error, disconnected

    var label: String {
        switch self {
        case .idle: "等待中"
        case .thinking: "思考中"
        case .streaming: "输出中"
        case .completed: "已完成"
        case .attention: "需操作"
        case .error: "异常"
        case .disconnected: "失联"
        }
    }

    var isRunning: Bool { self == .thinking || self == .streaming }
}

enum AIProvider: String, Codable, CaseIterable, Sendable {
    case chatgpt, claude, codex, yuanbao, deepseek

    var label: String {
        switch self {
        case .chatgpt: "ChatGPT"
        case .claude: "Claude"
        case .codex: "Codex"
        case .yuanbao: "元宝"
        case .deepseek: "DeepSeek"
        }
    }

    var glyph: String {
        switch self {
        case .chatgpt: "◉"
        case .claude: "✦"
        case .codex: "⌘"
        case .yuanbao: "元"
        case .deepseek: "鲸"
        }
    }
}

struct AIJobSnapshot: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var provider: AIProvider
    var tabId: Int?
    var windowId: Int?
    var pageTitle: String
    var state: AIJobState
    var startedAt: Date?
    var lastChangedAt: Date
    var lastHeartbeatAt: Date
    var needsAttention: Bool
    var source: String

    var elapsed: TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, Date().timeIntervalSince(startedAt))
    }

    var shortID: String {
        let raw = id.split(separator: ":").last.map(String.init) ?? id
        return String(raw.suffix(6)).uppercased()
    }

    var sourceBadge: String {
        if source == "demo:web" { return "WEB" }
        if source == "demo:app" { return "APP" }
        if source == "demo:codex" { return "TASK \(shortID)" }
        if source == "codex" { return "TASK \(shortID)" }
        if source == "browser" { return "WEB" }
        if source.hasPrefix("desktop:") { return "APP" }
        return "LOCAL"
    }
}

struct BrowserEvent: Codable, Sendable {
    var type: String?
    var token: String
    var provider: AIProvider?
    var tabId: Int?
    var windowId: Int?
    var pageTitle: String?
    var state: AIJobState?
    var startedAt: Date?
    var lastChangedAt: Date?
    var needsAttention: Bool?
}

struct HUDSettings: Codable, Equatable {
    var opacity = 0.94
    var collapsed = false
    var launchAtLogin = false
    var hiddenProviders: Set<AIProvider> = []
    var collapsedProviders: Set<AIProvider> = []
}
