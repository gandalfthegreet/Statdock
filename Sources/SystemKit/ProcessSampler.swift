import Darwin
import Foundation

private let procPidTaskInfo: Int32 = 4

/// Per-process CPU (delta) and resident size via `libproc`.
public struct ProcessCPUEntry: Sendable, Identifiable {
    public let id: Int32
    public let name: String
    public let cpuPercent: Double
}

public struct ProcessMemoryEntry: Sendable, Identifiable {
    public let id: Int32
    public let name: String
    public let residentBytes: UInt64
}

public final class ProcessSampler: @unchecked Sendable {
    private var priorCPU: [Int32: (u: UInt64, s: UInt64)] = [:]
    private let lock = NSLock()

    public init() {}

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        priorCPU.removeAll()
    }

    /// Wall time between this and the previous `sampleCPU` call, in nanoseconds (must be > 0 for meaningful %).
    public func sampleCPU(wallNanos: UInt64, limit: Int = 8) -> [ProcessCPUEntry] {
        lock.lock()
        defer { lock.unlock() }

        guard wallNanos > 0 else { return [] }

        let pids = allPIDs()
        var scored: [(Int32, String, Double)] = []

        for pid in pids where pid > 0 {
            guard let task = readTaskInfo(pid: pid) else { continue }
            if let prev = priorCPU[pid] {
                let du = task.user &- prev.u
                let ds = task.system &- prev.s
                let cpuNs = du &+ ds
                let pct = Double(cpuNs) / Double(wallNanos) * 100.0
                if pct >= 0.1 {
                    scored.append((pid, processName(pid: pid), pct))
                }
            }
            priorCPU[pid] = (task.user, task.system)
        }

        let alive = Set(pids)
        priorCPU = priorCPU.filter { alive.contains($0.key) }

        scored.sort { $0.2 > $1.2 }
        let filtered = scored.filter { ApplicationProcessFilter.isUserApplication(pid: $0.0) }
        return filtered.prefix(limit).map {
            ProcessCPUEntry(id: $0.0, name: $0.1, cpuPercent: $0.2)
        }
    }

    public func topMemory(limit: Int = 8) -> [ProcessMemoryEntry] {
        let pids = allPIDs()
        var rows: [(Int32, String, UInt64)] = []
        for pid in pids where pid > 0 {
            guard let task = readTaskInfo(pid: pid) else { continue }
            rows.append((pid, processName(pid: pid), task.resident))
        }
        rows.sort { $0.2 > $1.2 }
        let filtered = rows.filter { ApplicationProcessFilter.isUserApplication(pid: $0.0) }
        return filtered.prefix(limit).map { ProcessMemoryEntry(id: $0.0, name: $0.1, residentBytes: $0.2) }
    }

    private func allPIDs() -> [pid_t] {
        let n = proc_listallpids(nil, 0)
        guard n > 0 else { return [] }
        var buf = [pid_t](repeating: 0, count: Int(n))
        let got = proc_listallpids(&buf, Int32(buf.count * MemoryLayout<pid_t>.size))
        guard got > 0 else { return [] }
        return buf
    }

    private func readTaskInfo(pid: pid_t) -> (user: UInt64, system: UInt64, resident: UInt64)? {
        var raw = [UInt8](repeating: 0, count: 256)
        let r = raw.withUnsafeMutableBytes { ptr in
            proc_pidinfo(pid, procPidTaskInfo, 0, ptr.baseAddress!, Int32(ptr.count))
        }
        guard r > 0 else { return nil }
        return raw.withUnsafeBytes { buf in
            let resident = buf.load(fromByteOffset: 8, as: UInt64.self)
            let user = buf.load(fromByteOffset: 16, as: UInt64.self)
            let system = buf.load(fromByteOffset: 24, as: UInt64.self)
            return (user, system, resident)
        }
    }

    private func processName(pid: pid_t) -> String {
        var path = [CChar](repeating: 0, count: 4096)
        let len = proc_pidpath(pid, &path, UInt32(path.count))
        if len > 0 {
            let nul = path.firstIndex(of: 0) ?? path.endIndex
            let bytes = path[..<nul].map { UInt8(bitPattern: $0) }
            let s = String(decoding: bytes, as: UTF8.self)
            return (s as NSString).lastPathComponent
        }
        return "pid \(pid)"
    }
}
