import Darwin
import Foundation

/// Heuristic: keep **.app / Contents / MacOS** GUI apps; drop helpers, XPC, system daemons, etc.
public enum ApplicationProcessFilter {
    /// Full executable path from `proc_pidpath`.
    public static func executablePath(pid: pid_t) -> String? {
        guard pid >= 0 else { return nil }
        var path = [CChar](repeating: 0, count: 4096)
        let n = proc_pidpath(pid, &path, UInt32(path.count))
        guard n > 0 else { return nil }
        let end = path.firstIndex(of: 0) ?? path.endIndex
        let bytes = path[..<end].map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public static func isUserApplication(pid: pid_t) -> Bool {
        guard pid > 0, let path = executablePath(pid: pid) else { return false }
        return isUserApplication(executablePath: path)
    }

    public static func isUserApplication(executablePath path: String) -> Bool {
        let p = path
        if p.contains("/Contents/Helpers/") { return false }
        if p.contains("/Contents/XPCServices/") { return false }
        if p.contains("/Contents/PlugIns/") { return false }
        if p.contains("/Contents/Library/LoginItems/") { return false }
        if p.hasPrefix("/System/Library/") && !p.contains(".app/") { return false }
        if p.hasPrefix("/usr/libexec/") { return false }
        if p.hasPrefix("/sbin/") || p.hasPrefix("/bin/") { return false }
        if p.contains(".app/Contents/MacOS/") { return true }
        return false
    }

    /// Parse `nettop` key like `Google Chrome.123` → PID `123`.
    public static func pidFromNettopKey(_ key: String) -> pid_t? {
        guard let dot = key.lastIndex(of: ".") else { return nil }
        let tail = String(key[key.index(after: dot)...])
        guard let v = Int32(tail) else { return nil }
        return v
    }
}
