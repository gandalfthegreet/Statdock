import Darwin
import Foundation

/// Logical / physical CPU counts from `hw.*` sysctl (cheap, no subprocess).
public enum ProcessorInfo {
    public static func logicalCPUCount() -> Int {
        max(1, ProcessInfo.processInfo.processorCount)
    }

    public static func physicalCPUCount() -> Int {
        guard let n = sysctlInt32("hw.physicalcpu"), n > 0 else {
            return logicalCPUCount()
        }
        return Int(n)
    }

    /// Rough estimate: share of logical processors implied by aggregate CPU% (0…logical).
    public static func estimatedActiveCores(cpuUsagePercent: Double) -> Int {
        let n = logicalCPUCount()
        let x = (cpuUsagePercent / 100.0) * Double(n)
        return max(0, min(n, Int(x.rounded())))
    }

    private static func sysctlInt32(_ name: String) -> Int32? {
        var v: Int32 = 0
        var len = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &v, &len, nil, 0) == 0 else { return nil }
        return v
    }
}
