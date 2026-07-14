import AppKit
import Darwin

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?
    private var instanceLock: InstanceLock?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let lock = InstanceLock.acquire() else {
            DistributedNotificationCenter.default().postNotificationName(.aiProgressHUDReopen, object: nil)
            NSApp.terminate(nil)
            return
        }
        instanceLock = lock
        controller = AppController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}

private final class InstanceLock {
    private let descriptor: Int32
    private init(_ descriptor: Int32) { self.descriptor = descriptor }

    deinit {
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }

    static func acquire() -> InstanceLock? {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/AIProgressHUD", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let descriptor = open(directory.appendingPathComponent("app.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { return nil }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return nil
        }
        return InstanceLock(descriptor)
    }
}
