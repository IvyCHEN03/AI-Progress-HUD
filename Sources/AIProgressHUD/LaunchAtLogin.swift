import Foundation

enum LaunchAtLogin {
    private static let label = "com.local.ai-progress-hud.agent"

    static func setEnabled(_ enabled: Bool) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("Library/LaunchAgents/\(label).plist")
        if enabled {
            guard let executable = Bundle.main.executableURL?.path else { return }
            let plist: [String: Any] = [
                "Label": label, "ProgramArguments": [executable], "RunAtLoad": true,
                "KeepAlive": ["SuccessfulExit": false], "ProcessType": "Interactive"
            ]
            guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else { return }
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
            run(["bootout", "gui/\(getuid())", url.path])
            run(["bootstrap", "gui/\(getuid())", url.path])
        } else {
            run(["bootout", "gui/\(getuid())", url.path])
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func run(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        try? process.run()
    }
}
