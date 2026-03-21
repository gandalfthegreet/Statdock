import Darwin
import Foundation

/// Aggregate bytes in/out across non-loopback interfaces (`getifaddrs` / `AF_LINK` `if_data`).
public enum InterfaceThroughput {
    public static func totalBytes() -> (inBytes: UInt64, outBytes: UInt64)? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(first) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let family = p.pointee.ifa_addr.pointee.sa_family
            if family == UInt8(AF_LINK), let raw = p.pointee.ifa_data {
                let name = String(cString: p.pointee.ifa_name)
                if name.hasPrefix("lo") {
                    ptr = p.pointee.ifa_next
                    continue
                }
                raw.withMemoryRebound(to: if_data.self, capacity: 1) { data in
                    totalIn += UInt64(data.pointee.ifi_ibytes)
                    totalOut += UInt64(data.pointee.ifi_obytes)
                }
            }
            ptr = p.pointee.ifa_next
        }
        return (totalIn, totalOut)
    }
}

/// Delta-based Mbps-style sample (call on a fixed interval).
public final class InterfaceThroughputSampler: @unchecked Sendable {
    private var prevIn: UInt64 = 0
    private var prevOut: UInt64 = 0
    private var primed = false
    private let lock = NSLock()

    public init() {}

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        primed = false
        prevIn = 0
        prevOut = 0
    }

    /// Returns (download B/s, upload B/s), or `nil` on first sample.
    public func sampleBytesPerSecond(wallNanos: UInt64) -> (down: Double, up: Double)? {
        lock.lock()
        defer { lock.unlock() }

        guard wallNanos > 0, let totals = InterfaceThroughput.totalBytes() else { return nil }
        let inB = totals.inBytes
        let outB = totals.outBytes

        guard primed else {
            primed = true
            prevIn = inB
            prevOut = outB
            return nil
        }

        let di = inB &- prevIn
        let dout = outB &- prevOut
        prevIn = inB
        prevOut = outB

        let sec = Double(wallNanos) / 1_000_000_000.0
        guard sec > 0 else { return nil }
        return (Double(di) / sec, Double(dout) / sec)
    }
}
