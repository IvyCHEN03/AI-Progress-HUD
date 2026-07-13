import AppKit
import SwiftUI

final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppController: NSObject, NSWindowDelegate {
    let store = JobStore()
    private lazy var server = LocalHTTPServer(pairingToken: store.pairingToken)
    private var codexMonitor: CodexMonitor!
    private var desktopMonitor: DesktopAIMonitor!
    private var statusItem: NSStatusItem!
    private var panel: HUDPanel!
    private var settingsWindow: NSWindow?

    override init() {
        super.init()
        codexMonitor = CodexMonitor(store: store)
        desktopMonitor = DesktopAIMonitor(store: store)
        configurePanel()
        configureStatusItem()
        configureBindings()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showFromReopen),
            name: .aiProgressHUDReopen,
            object: nil
        )
        server.start()
        codexMonitor.start()
        desktopMonitor.start()
        panel.orderFrontRegardless()
    }

    func stop() {
        server.stop()
        codexMonitor.stop()
        desktopMonitor.stop()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    private func configureBindings() {
        server.onEvent = { [weak store] event in Task { @MainActor in store?.receive(event) } }
        server.onStatus = { [weak store] online in Task { @MainActor in store?.setServerOnline(online) } }
        server.onBrowserHeartbeat = { [weak store] in Task { @MainActor in store?.markBrowserBridgeSeen() } }
        store.activateBrowserTab = { [weak server] tabId, windowId in server?.enqueueActivate(tabId: tabId, windowId: windowId) }
        store.settingsChanged = { settings in LaunchAtLogin.setEnabled(settings.launchAtLogin) }
        store.onRequestSettings = { [weak self] in self?.openSettings() }
        store.onRequestQuit = { NSApp.terminate(nil) }
    }

    private func configurePanel() {
        let host = NSHostingController(rootView: HUDView(store: store))
        panel = HUDPanel(
            contentRect: NSRect(x: 0, y: 0, width: 354, height: 160),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered, defer: false
        )
        panel.contentViewController = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 354, height: 54)
        panel.maxSize = NSSize(width: 354, height: 720)
        panel.delegate = self
        positionAtRightEdge()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "AI Progress HUD")
        let menu = NSMenu()
        menu.addItem(withTitle: "显示/隐藏血条", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(withTitle: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 AI Progress HUD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    @objc private func togglePanel() {
        panel.isVisible ? panel.orderOut(nil) : panel.orderFrontRegardless()
    }

    @objc private func showFromReopen() {
        panel.orderFrontRegardless()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView(store: store) { [weak self] in self?.codexMonitor.requestPermission() }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "AI Progress HUD 设置"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowDidEndLiveResize(_ notification: Notification) { snapToEdge() }
    func windowDidMove(_ notification: Notification) { NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(snapToEdge), object: nil); perform(#selector(snapToEdge), with: nil, afterDelay: 0.18) }

    @objc private func snapToEdge() {
        guard let screen = panel.screen else { return }
        let visible = screen.visibleFrame
        var frame = panel.frame
        let leftDistance = abs(frame.minX - visible.minX)
        let rightDistance = abs(visible.maxX - frame.maxX)
        if min(leftDistance, rightDistance) < 48 {
            frame.origin.x = leftDistance < rightDistance ? visible.minX + 8 : visible.maxX - frame.width - 8
            frame.origin.y = min(max(frame.origin.y, visible.minY + 8), visible.maxY - frame.height - 8)
            panel.setFrame(frame, display: true, animate: true)
        }
    }

    private func positionAtRightEdge() {
        guard let visible = NSScreen.main?.visibleFrame else { return }
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: visible.maxX - size.width - 18, y: visible.midY - size.height / 2))
    }
}

extension Notification.Name {
    static let aiProgressHUDReopen = Notification.Name("com.local.ai-progress-hud.reopen")
}
