import Foundation
import IOKit.ps

/// Best-effort battery snapshot from IOKit power sources (no Microverse code).
public enum BatteryReader {
    public struct Snapshot: Sendable {
        /// Remaining charge 0–100.
        public let percent: Int
        public let isCharging: Bool
        public let isPluggedIn: Bool
        public let timeRemainingMinutes: Int?

        public let currentChargeDescription: String?
        public let maxCapacityDescription: String?
        /// Full-charge capacity vs design (100% = new).
        public let healthPercent: Int?
        public let cycleCount: Int?
    }

    public static func currentSnapshot() -> Snapshot? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return nil }

        for src in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, src)?.takeUnretainedValue() as? [String: Any]
            else { continue }

            guard desc[kIOPSMaxCapacityKey] != nil, desc[kIOPSCurrentCapacityKey] != nil else { continue }

            let maxCapScale = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let curCapScale = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let pct = max(0, min(100, maxCapScale > 0 ? (curCapScale * 100) / maxCapScale : curCapScale))

            let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
            let powerSource = desc[kIOPSPowerSourceStateKey] as? String
            let isAC = powerSource == kIOPSACPowerValue

            var minutes: Int?
            if let raw = desc[kIOPSTimeToEmptyKey] as? Int, raw > 0 {
                minutes = raw
            }

            let rawCur = desc["AppleRawCurrentCapacity"] as? Int
            let rawMax = desc["AppleRawMaxCapacity"] as? Int
            let designMah = desc[kIOPSDesignCapacityKey] as? Int

            let currentStr: String?
            if let c = rawCur, let m = rawMax, m > 0 {
                currentStr = "\(c) mAh · \(pct)%"
            } else {
                currentStr = "\(pct)%"
            }

            let maxStr: String?
            if let m = rawMax, m > 0 {
                maxStr = "\(m) mAh (full charge)"
            } else if maxCapScale > 0 {
                maxStr = "\(maxCapScale) (system scale)"
            } else {
                maxStr = nil
            }

            let health: Int?
            if let d = designMah, d > 0, let f = rawMax, f > 0 {
                health = max(0, min(100, (f * 100) / d))
            } else {
                health = nil
            }

            let cycles = desc["CycleCount"] as? Int

            return Snapshot(
                percent: pct,
                isCharging: isCharging,
                isPluggedIn: isAC,
                timeRemainingMinutes: minutes,
                currentChargeDescription: currentStr,
                maxCapacityDescription: maxStr,
                healthPercent: health,
                cycleCount: cycles
            )
        }

        return nil
    }
}
