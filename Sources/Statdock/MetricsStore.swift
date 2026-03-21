import Foundation
import SwiftUI
import SystemKit

@MainActor
final class MetricsStore: ObservableObject {
    static let shared = MetricsStore()

    @Published private(set) var cpuTotal: Double = 0
    @Published private(set) var memoryPercent: Double = 0
    @Published private(set) var usedMemoryBytes: UInt64 = 0
    @Published private(set) var totalMemoryBytes: UInt64 = 0
    @Published private(set) var freeMemoryBytes: UInt64 = 0
    @Published private(set) var cachedFilesBytes: UInt64 = 0
    @Published private(set) var memoryCompressionRatio: Double?
    @Published private(set) var batteryInfo: BatteryReader.Snapshot?
    let logicalProcessorCount: Int = ProcessorInfo.logicalCPUCount()
    let physicalProcessorCount: Int = ProcessorInfo.physicalCPUCount()
    @Published private(set) var activeProcessorCoresEstimate: Int = 0
    @Published private(set) var networkDownBps: Double = 0
    @Published private(set) var networkUpBps: Double = 0
    @Published private(set) var topCPU: [ProcessCPUEntry] = []
    @Published private(set) var topMemory: [ProcessMemoryEntry] = []
    @Published private(set) var topNetwork: [NetworkProcessRow] = []

    private let hostCPU = HostCPUState()
    private let processSampler = ProcessSampler()
    private let nettopSampler = NettopSampler()
    private let interfaceThroughput = InterfaceThroughputSampler()
    private var tickTask: Task<Void, Never>?
    private var lastTickMonotonic: UInt64?
    private var clientCount = 0

    private var previousCpuAdaptive: Double?
    private var previousMemPercentAdaptive: Double?
    private var stableAdaptiveTicks: Int = 0

    private init() {}

    func acquire() {
        clientCount += 1
        guard clientCount == 1 else { return }
        processSampler.reset()
        nettopSampler.reset()
        interfaceThroughput.reset()
        lastTickMonotonic = nil
        previousCpuAdaptive = nil
        previousMemPercentAdaptive = nil
        stableAdaptiveTicks = 0
        tickTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func release() {
        clientCount = max(0, clientCount - 1)
        guard clientCount == 0 else { return }
        tickTask?.cancel()
        tickTask = nil
    }

    private func runLoop() async {
        while !Task.isCancelled {
            let mono = DispatchTime.now().uptimeNanoseconds
            let wallNanos: UInt64
            if let prev = lastTickMonotonic {
                wallNanos = mono &- prev
            } else {
                wallNanos = 0
            }
            lastTickMonotonic = mono

            let cpu = await Task.detached(priority: .utility) { [hostCPU] in
                hostCPU.usagePercent()
            }.value

            let mem = await Task.detached(priority: .utility) {
                HostMetrics.memorySample()
            }.value

            let bat = await Task.detached(priority: .utility) {
                BatteryReader.currentSnapshot()
            }.value

            let wallForProcess = wallNanos > 50_000_000 ? wallNanos : 0
            let topC: [ProcessCPUEntry] = await Task.detached(priority: .utility) { [processSampler] in
                guard wallForProcess > 0 else { return [] }
                return processSampler.sampleCPU(wallNanos: wallForProcess, limit: 8)
            }.value

            let topM = await Task.detached(priority: .utility) { [processSampler] in
                processSampler.topMemory(limit: 8)
            }.value

            let intervalSec = wallNanos > 0 ? Double(wallNanos) / 1_000_000_000.0 : 0
            let topN: [NetworkProcessRow] = await Task.detached(priority: .utility) { [nettopSampler] in
                guard intervalSec > 0.05 else { return [] }
                return nettopSampler.sample(deltaSeconds: intervalSec, limit: 12)
            }.value

            if wallNanos > 0, let rates = interfaceThroughput.sampleBytesPerSecond(wallNanos: wallNanos) {
                networkDownBps = rates.down
                networkUpBps = rates.up
            }

            cpuTotal = cpu
            activeProcessorCoresEstimate = ProcessorInfo.estimatedActiveCores(cpuUsagePercent: cpu)
            if let m = mem {
                memoryPercent = m.usagePercent
                usedMemoryBytes = m.usedBytes
                totalMemoryBytes = m.totalBytes
                freeMemoryBytes = m.freeBytes
                cachedFilesBytes = m.cachedFilesBytes
                memoryCompressionRatio = m.compressionRatio
            }
            batteryInfo = bat
            topCPU = topC
            topMemory = topM
            topNetwork = topN

            let memPct = mem?.usagePercent ?? memoryPercent
            let sleepSec: Double = {
                guard AppSettings.shared.adaptivePolling else {
                    return UserDefaults.standard.object(forKey: "statdock.pollIntervalSeconds") as? Double ?? 2.5
                }
                let cpuDelta = previousCpuAdaptive.map { abs(cpu - $0) } ?? 100
                let memDelta = previousMemPercentAdaptive.map { abs(memPct - $0) } ?? 100
                let stressed = cpu >= 38 || memPct >= 88
                let moving = cpuDelta >= 6 || memDelta >= 4
                let interval: Double
                if stressed || moving {
                    stableAdaptiveTicks = 0
                    interval = 2
                } else {
                    stableAdaptiveTicks += 1
                    if stableAdaptiveTicks < 4 {
                        interval = 2
                    } else {
                        let extra = stableAdaptiveTicks - 4
                        interval = min(30, 5 + Double(extra) * 1.6)
                    }
                }
                previousCpuAdaptive = cpu
                previousMemPercentAdaptive = memPct
                return interval
            }()

            let ns = UInt64(max(0.5, sleepSec) * 1_000_000_000.0)
            try? await Task.sleep(nanoseconds: ns)
        }
    }
}
