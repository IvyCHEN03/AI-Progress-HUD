import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: JobStore
    let runningAppPath: String
    let requestAccessibility: () -> Void
    let resetAccessibilityBinding: () -> Void

    private var setupCount: Int {
        [store.serverOnline, store.browserReporting, store.accessibilityTrusted].filter { $0 }.count
    }

    private var desktopDetail: String {
        if store.accessibilityTrusted { return "Accessibility granted" }
        if store.accessibilityPreviouslyGranted { return "Granted before · relaunch or repair only if desktop apps are missing" }
        return "Enable once for desktop app state"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Quick setup").font(.headline)
                            Text("\(setupCount)/3 connections ready").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        ProgressView(value: Double(setupCount), total: 3).frame(width: 120)
                    }
                    SetupRow(ok: store.serverOnline, title: "Local bridge", detail: "127.0.0.1:17321")
                    SetupRow(ok: store.browserReporting, title: "Browser extension", detail: store.browserReporting ? "Connected · ready for AI tabs" : "Pair the extension, then reload it")
                    SetupRow(ok: store.accessibilityTrusted, title: "Desktop apps", detail: desktopDetail)
                    Button(store.demoMode ? "Exit demo mode" : "Preview with demo tasks") {
                        store.toggleDemoMode()
                    }
                }.padding(.vertical, 4)
            }

            Section("Browser · ChatGPT, Claude, Yuanbao, DeepSeek") {
                LabeledContent("Status", value: store.browserReporting ? "Connected" : "Not connected")
                LabeledContent("Pairing token") {
                    HStack {
                        Text(store.pairingToken).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(store.pairingToken, forType: .string)
                        }
                    }
                }
                HStack {
                    Button("Show extension folder") {
                        let bundled = Bundle.main.resourceURL?.appendingPathComponent("Extension")
                        let development = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("Extension")
                        let path: String
                        if let bundled, FileManager.default.fileExists(atPath: bundled.path) { path = bundled.path }
                        else { path = development.path }
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                    }
                    Button("Copy chrome://extensions") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("chrome://extensions", forType: .string)
                    }
                }
                Text("Load the Extension folder once. Saving the token automatically injects all open supported tabs.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Desktop · ChatGPT, Claude, Yuanbao") {
                LabeledContent("Accessibility", value: store.accessibilityTrusted ? "Granted" : (store.accessibilityPreviouslyGranted ? "Previously granted" : "Not granted"))
                if !store.accessibilityTrusted && !store.accessibilityPreviouslyGranted {
                    HStack {
                        Button("Grant Accessibility permission") {
                            requestAccessibility()
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                        Button("Reset permission binding") {
                            resetAccessibilityBinding()
                        }
                    }
                    Text("Grant once for desktop app windows. Browser tabs and Codex local tasks work without this permission.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if !store.accessibilityTrusted {
                    HStack {
                        Button("Repair Accessibility permission") {
                            requestAccessibility()
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                        Button("Reset permission binding") {
                            resetAccessibilityBinding()
                        }
                    }
                    Text("This Mac has granted AI Progress HUD before, but macOS is not trusting the currently running copy. Keep one app copy, then toggle this exact app off and on once in Accessibility.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                LabeledContent("Current app") {
                    HStack {
                        Text(runningAppPath)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                        Button("Reveal") {
                            NSWorkspace.shared.selectFile(runningAppPath, inFileViewerRootedAtPath: "")
                        }
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(runningAppPath, forType: .string)
                        }
                    }
                }
                Text("Only window titles and control labels are inspected. Conversation bodies are never stored.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Codex") {
                LabeledContent("Thread sync", value: store.codexReporting ? "Live" : "Waiting for activity")
                Text("Codex rows use the conversation title only. No Accessibility permission is required.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Appearance") {
                Slider(value: $store.settings.opacity, in: 0.45...1) { Text("Opacity") }
                Toggle("Launch at login", isOn: $store.settings.launchAtLogin)
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    Toggle("Show \(provider.label)", isOn: Binding(
                        get: { !store.settings.hiddenProviders.contains(provider) },
                        set: { visible in
                            if visible { store.settings.hiddenProviders.remove(provider) }
                            else { store.settings.hiddenProviders.insert(provider) }
                        }
                    ))
                }
            }

            Section("Privacy & diagnostics") {
                Text("100% local. No account, telemetry, prompts, or responses leave your Mac.")
                    .font(.caption).foregroundStyle(.secondary)
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")
                Button("Clear current task state", role: .destructive) { store.clearData() }
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .frame(width: 560, height: 680)
    }
}

private struct SetupRow: View {
    let ok: Bool
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(ok ? .green : .orange)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
