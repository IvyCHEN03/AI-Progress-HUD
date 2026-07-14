import AppKit
import ApplicationServices
import Foundation

@MainActor
final class DesktopAIMonitor {
    private struct Target {
        let provider: AIProvider
        let bundleIDs: [String]
        let fallbackName: String
    }

    private let targets = [
        Target(provider: .chatgpt, bundleIDs: ["com.openai.codex", "com.openai.chat"], fallbackName: "ChatGPT"),
        Target(provider: .claude, bundleIDs: ["com.anthropic.claudefordesktop"], fallbackName: "Claude"),
        Target(provider: .yuanbao, bundleIDs: ["com.tencent.yuanbao"], fallbackName: "元宝"),
        Target(provider: .deepseek, bundleIDs: ["com.deepseek.chat", "com.deepseek.DeepSeek"], fallbackName: "DeepSeek"),
        Target(provider: .inspiration, bundleIDs: ["com.local.clipboard-station"], fallbackName: "灵感悬浮球")
    ]

    private weak var store: JobStore?
    private var timer: Timer?

    init(store: JobStore) { self.store = store }

    func start() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func scan() {
        let trusted = AXIsProcessTrusted()
        store?.setAccessibilityTrusted(trusted)
        var seen: Set<String> = []
        for target in targets {
            for bundleID in target.bundleIDs {
                for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
                    if app.bundleURL?.path.hasPrefix("/Volumes/") == true { continue }
                    let key = "\(app.processIdentifier)"
                    let id = "desktop:\(bundleID):\(key)"
                    var title: String
                    var state: AIJobState
                    let fallback = app.localizedName ?? target.fallbackName
                    if !trusted {
                        title = fallback
                        state = .idle
                    } else {
                        let appElement = AXUIElementCreateApplication(app.processIdentifier)
                        let windows = windows(of: appElement)
                        if windows.isEmpty {
                            title = fallback
                            state = .idle
                        } else {
                            let snapshots = windows.map { window in
                                let labels = controlLabels(in: window, depth: 0).lowercased()
                                return (title: taskTitle(in: window, fallback: fallback), state: detectState(from: labels))
                            }
                            title = snapshots.first { !$0.title.isEmpty && $0.title != fallback }?.title ?? fallback
                            state = snapshots.map(\.state).min(by: { priority($0) < priority($1) }) ?? .idle
                        }
                    }
                    if target.provider == .inspiration {
                        title = target.fallbackName
                        state = .idle
                    }
                    guard shouldShowDesktopRow(provider: target.provider, state: state) else { continue }
                    seen.insert(id)
                    store?.upsertDesktop(
                        provider: target.provider, bundleID: bundleID,
                        windowKey: key, title: title, detectedState: state
                    )
                }
            }
        }
        store?.removeMissingDesktop(ids: seen)
    }

    private func shouldShowDesktopRow(provider: AIProvider, state: AIJobState) -> Bool {
        if provider == .inspiration { return true }
        return state.isRunning || state == .attention || state == .error
    }

    private func priority(_ state: AIJobState) -> Int {
        switch state {
        case .attention, .error: 0
        case .streaming: 1
        case .thinking: 2
        case .completed: 3
        case .idle: 4
        case .disconnected: 5
        }
    }

    private func detectState(from labels: String) -> AIJobState {
        if containsAny(labels, ["stop generating", "stop response", "停止生成", "停止回答", "cancel task", "stop research"]) { return .streaming }
        if containsAny(labels, ["thinking", "working", "researching", "思考中", "生成中", "正在研究"]) { return .thinking }
        if containsAny(labels, ["captcha", "verify", "rate limit", "验证码", "需要验证", "频率限制"]) { return .attention }
        if containsAny(labels, ["response error", "generation failed", "网络错误", "生成失败"]) { return .error }
        if containsAny(labels, ["completed", "task complete", "已完成", "任务完成"]) { return .completed }
        return .idle
    }

    private func containsAny(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0) }
    }

    private func windows(of app: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func taskTitle(in window: AXUIElement, fallback: String) -> String {
        if let selectedTitle = selectedConversationTitle(in: window, depth: 0),
           selectedTitle.caseInsensitiveCompare(fallback) != .orderedSame {
            return selectedTitle
        }
        if let webTitle = firstWebAreaTitle(in: window, depth: 0) {
            let cleaned = webTitle
                .replacingOccurrences(of: " - Claude", with: "")
                .replacingOccurrences(of: " - ChatGPT", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty, cleaned.caseInsensitiveCompare(fallback) != .orderedSame {
                return String(cleaned.prefix(72))
            }
        }
        return stringAttribute(window, kAXTitleAttribute).flatMap { $0.isEmpty ? nil : String($0.prefix(72)) } ?? fallback
    }

    private func selectedConversationTitle(in element: AXUIElement, depth: Int) -> String? {
        guard depth < 8 else { return nil }
        let role = stringAttribute(element, kAXRoleAttribute) ?? ""
        var selectedValue: CFTypeRef?
        let isSelected = AXUIElementCopyAttributeValue(element, kAXSelectedAttribute as CFString, &selectedValue) == .success
            && (selectedValue as? Bool == true)
        if isSelected, ["AXLink", "AXRow", "AXButton", "AXStaticText"].contains(role) {
            for attribute in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] {
                if let raw = stringAttribute(element, attribute) {
                    let value = raw.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty, value.count <= 240 { return value }
                }
            }
        }
        for child in children(of: element).prefix(180) {
            if let found = selectedConversationTitle(in: child, depth: depth + 1) { return found }
        }
        return nil
    }

    private func firstWebAreaTitle(in element: AXUIElement, depth: Int) -> String? {
        guard depth < 7 else { return nil }
        let role = stringAttribute(element, kAXRoleAttribute) ?? ""
        if role == "AXWebArea", let title = stringAttribute(element, kAXTitleAttribute), !title.isEmpty { return title }
        for child in children(of: element).prefix(100) {
            if let found = firstWebAreaTitle(in: child, depth: depth + 1) { return found }
        }
        return nil
    }

    private func controlLabels(in element: AXUIElement, depth: Int) -> String {
        guard depth < 8 else { return "" }
        let role = stringAttribute(element, kAXRoleAttribute) ?? ""
        var labels: [String] = []
        if ["AXButton", "AXCheckBox", "AXRadioButton"].contains(role) {
            for attribute in [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute] {
                if let value = stringAttribute(element, attribute), value.count <= 100 { labels.append(value) }
            }
        }
        for child in children(of: element).prefix(160) {
            labels.append(controlLabels(in: child, depth: depth + 1))
        }
        return labels.joined(separator: " ")
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func stringAttribute(_ element: AXUIElement, _ name: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? String
    }
}
