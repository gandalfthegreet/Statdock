import AppKit

enum AppProcessTermination {
    static func canRequestTermination(pid: pid_t) -> Bool {
        guard pid > 0, pid != ProcessInfo.processInfo.processIdentifier else { return false }
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return false }
        return app.bundleURL != nil
    }

    static func terminate(pid: pid_t) {
        NSRunningApplication(processIdentifier: pid)?.terminate()
    }

    static func forceTerminate(pid: pid_t) {
        NSRunningApplication(processIdentifier: pid)?.forceTerminate()
    }
}
