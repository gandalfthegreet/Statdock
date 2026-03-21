import Darwin
import Foundation

/// Parses `nettop` CSV (`-P -L 1 -s 1 -x`) and estimates per-process throughput from consecutive samples.
public struct NetworkProcessRow: Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let bytesPerSecond: Double
    public let pid: pid_t?
}

public final class NettopSampler: @unchecked Sendable {
    private var previous: [String: UInt64] = [:]
    private var lastEmitted: [NetworkProcessRow] = []
    private var lastEmittedAt: TimeInterval = 0
    private let lock = NSLock()

    /// Keep last non-empty list on-screen briefly when a sample is empty (bursty traffic + long poll intervals).
    private let stickySeconds: TimeInterval = 25

    public init() {}

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        previous.removeAll()
        lastEmitted.removeAll()
        lastEmittedAt = 0
    }

    /// Call periodically with wall-interval `deltaSeconds` between calls; first call returns [].
    public func sample(deltaSeconds: TimeInterval, limit: Int = 12) -> [NetworkProcessRow] {
        let nowMono = ProcessInfo.processInfo.systemUptime
        let totals = Self.snapshotTotals()
        lock.lock()
        defer { lock.unlock() }

        guard deltaSeconds > 0.05 else { return stickyOrEmpty(nowMono: nowMono) }

        // Bad/empty parse: do not wipe `previous` or we lose deltas next tick.
        guard let totals, !totals.isEmpty else {
            return stickyOrEmpty(nowMono: nowMono)
        }

        guard !previous.isEmpty else {
            previous = totals
            return []
        }

        var rows: [(String, String, Double, pid_t?)] = []
        for (key, now) in totals {
            let prev = previous[key] ?? 0
            let d = now &- prev
            let bps = Double(d) / deltaSeconds
            guard d > 0, bps.isFinite, bps >= 0 else { continue }

            let pid = ApplicationProcessFilter.pidFromNettopKey(key)
            let name = key.split(separator: ".").dropLast().joined(separator: ".")
            let label = name.isEmpty ? key : String(name)
            rows.append((key, label, bps, pid))
        }
        previous = totals

        rows.sort { $0.2 > $1.2 }
        let minProminence: Double = 48
        let strong = rows.filter { $0.2 >= minProminence }
        let chosen = strong.count >= limit ? Array(strong.prefix(limit)) : Array(rows.prefix(limit))

        let mapped = chosen.map {
            NetworkProcessRow(id: $0.0, displayName: $0.1, bytesPerSecond: $0.2, pid: $0.3)
        }

        if !mapped.isEmpty {
            lastEmitted = mapped
            lastEmittedAt = nowMono
            return mapped
        }

        return stickyOrEmpty(nowMono: nowMono)
    }

    private func stickyOrEmpty(nowMono: TimeInterval) -> [NetworkProcessRow] {
        guard !lastEmitted.isEmpty, nowMono - lastEmittedAt < stickySeconds else {
            return []
        }
        return lastEmitted
    }

    private static func snapshotTotals() -> [String: UInt64]? {
        let csv = runNettop()
        guard !csv.isEmpty else { return nil }
        return parseTotals(csv: csv)
    }

    private static func runNettop() -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        p.arguments = ["-P", "-L", "1", "-s", "1", "-x"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do {
            try p.run()
        } catch {
            return ""
        }
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Keys: `process.pid` column; value: sum of bytes_in + bytes_out for that row (per line).
    static func parseTotals(csv: String) -> [String: UInt64]? {
        var lines = csv.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first else { return nil }
        lines.removeFirst()

        let cols = header.split(separator: ",", omittingEmptySubsequences: false).map {
            String($0).trimmingCharacters(in: .whitespaces)
        }
        guard let bi = cols.firstIndex(of: "bytes_in"),
              let bo = cols.firstIndex(of: "bytes_out")
        else {
            return aggregateFallback(lines: lines)
        }

        let procIdx = 1

        var totals: [String: UInt64] = [:]
        for line in lines {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false).map {
                String($0).trimmingCharacters(in: .whitespaces)
            }
            guard parts.count > max(procIdx, bi, bo) else { continue }
            let key = parts[procIdx]
            guard key.contains(".") else { continue }
            let rin = UInt64(parts[bi]) ?? 0
            let rout = UInt64(parts[bo]) ?? 0
            totals[key, default: 0] = totals[key, default: 0] &+ rin &+ rout
        }
        return totals.isEmpty ? nil : totals
    }

    private static func aggregateFallback(lines: [String]) -> [String: UInt64]? {
        var totals: [String: UInt64] = [:]
        for line in lines {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false).map {
                String($0).trimmingCharacters(in: .whitespaces)
            }
            guard parts.count > 5 else { continue }
            let key = parts[1]
            guard key.contains(".") else { continue }
            let rin = UInt64(parts[4]) ?? 0
            let rout = UInt64(parts[5]) ?? 0
            totals[key, default: 0] = totals[key, default: 0] &+ rin &+ rout
        }
        return totals.isEmpty ? nil : totals
    }
}
