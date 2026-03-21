import Darwin
import Foundation

/// Aggregate host CPU and memory via Mach `host_statistics` / `host_statistics64`.
public enum HostMetrics {
    public struct MemorySample: Sendable {
        /// Active + wired + compressor physical footprint (pressure-style “used”).
        public let usagePercent: Double
        public let usedBytes: UInt64
        public let totalBytes: UInt64
        public let freeBytes: UInt64
        /// File-backed pages (`external_page_count`), similar to “Cached files” in Activity Monitor.
        public let cachedFilesBytes: UInt64
        /// Uncompressed logical pages per physical compressor page (`total_uncompressed_pages_in_compressor` / `compressor_page_count`); `nil` if not compressing.
        public let compressionRatio: Double?
    }

    /// Instantaneous CPU usage 0–100 (all cores combined).
    static func cpuUsagePercent(since previous: inout HostCPULoad?) -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, ptr, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }

        let ticks = info.cpu_ticks
        let cur = HostCPULoad(
            user: UInt32(ticks.0),
            system: UInt32(ticks.1),
            idle: UInt32(ticks.2),
            nice: UInt32(ticks.3)
        )

        guard let prev = previous else {
            previous = cur
            return 0
        }

        let u = cur.user &- prev.user
        let s = cur.system &- prev.system
        let n = cur.nice &- prev.nice
        let i = cur.idle &- prev.idle
        let active = UInt64(u) &+ UInt64(s) &+ UInt64(n)
        let total = active &+ UInt64(i)
        previous = cur
        guard total > 0 else { return 0 }
        return Double(active) / Double(total) * 100.0
    }

    /// Rough memory pressure: (active + wired + compressor pages) × page size vs physical RAM.
    public static func memorySample() -> MemorySample? {
        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS, pageSize > 0 else { return nil }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }

        let phys = ProcessInfo.processInfo.physicalMemory
        guard phys > 0 else { return nil }

        let p = UInt64(pageSize)
        let free = UInt64(stats.free_count) &* p
        let cachedFiles = UInt64(stats.external_page_count) &* p
        let active = UInt64(stats.active_count) &* p
        let wired = UInt64(stats.wire_count) &* p
        let compressor = UInt64(stats.compressor_page_count) &* p
        let used = active &+ wired &+ compressor
        let pct = min(100, Double(used) / Double(phys) * 100)

        let uncomp = stats.total_uncompressed_pages_in_compressor
        let ratio: Double? = stats.compressor_page_count > 0
            ? Double(uncomp) / Double(stats.compressor_page_count)
            : nil

        return MemorySample(
            usagePercent: pct,
            usedBytes: used,
            totalBytes: phys,
            freeBytes: free,
            cachedFilesBytes: cachedFiles,
            compressionRatio: ratio
        )
    }
}

struct HostCPULoad {
    let user: UInt32
    let system: UInt32
    let idle: UInt32
    let nice: UInt32
}

/// Thread-safe holder for aggregate CPU tick deltas (call from background or main).
public final class HostCPUState: @unchecked Sendable {
    private var previous: HostCPULoad?
    private let lock = NSLock()

    public init() {}

    public func usagePercent() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return HostMetrics.cpuUsagePercent(since: &previous)
    }
}
