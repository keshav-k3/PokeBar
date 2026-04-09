//
//  SystemMonitor.swift
//  PokeBar
//
//  System monitoring service for CPU and memory tracking
//

import Foundation
import Darwin
import IOKit.ps

/// Polls Mach host statistics. Values are **indicative**, not identical to Activity Monitor’s
/// internal accounting, but CPU is standard aggregate utilization; RAM uses a common
/// “wired + active + compressed” model (see `updateMemoryUsage`).
class SystemMonitor: ObservableObject {
    @Published var stats = SystemStats()
    @Published var cpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []

    /// Maximum number of samples kept (60 s at 1 s interval).
    private let historyCapacity = 60

    private var timer: Timer?
    private let updateInterval: TimeInterval
    private let networkMonitor = NetworkMonitor()
    private var lastPublicIPLookup: Date?

    // CPU tracking
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private var previousTotalTicks: UInt64 = 0
    private var previousIdleTicks: UInt64 = 0

    // Callback for CPU updates
    var onCPUUpdate: ((Double) -> Void)?

    init(updateInterval: TimeInterval = 1.0) {
        self.updateInterval = updateInterval
    }

    func startMonitoring() {
        // Initial update
        updateStats()

        // Schedule periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        updateCPUUsage()
        updateMemoryUsage()
        updateNetworkStats()
        updateBatteryStats()
        refreshPublicIPIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.cpuHistory.append(self.stats.cpuUsage)
            if self.cpuHistory.count > self.historyCapacity {
                self.cpuHistory.removeFirst(self.cpuHistory.count - self.historyCapacity)
            }
            self.memoryHistory.append(self.stats.memoryPercentage)
            if self.memoryHistory.count > self.historyCapacity {
                self.memoryHistory.removeFirst(self.memoryHistory.count - self.historyCapacity)
            }

            self.objectWillChange.send()
            self.onCPUUpdate?(self.stats.cpuUsage)
        }
    }

    /// Host-wide CPU: non-idle tick delta / total tick delta across all cores → 0–100%.
    /// First sample after launch is 0% until a second sample exists.
    private func updateCPUUsage() {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            stats.cpuUsage = 0.0
            return
        }

        let cpuLoadInfo = cpuInfo.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(numCPUsU)) { $0 }

        var totalTicks: UInt64 = 0
        var idleTicks: UInt64 = 0

        for i in 0..<Int(numCPUsU) {
            let cpu = cpuLoadInfo[i]
            totalTicks += UInt64(cpu.cpu_ticks.0) + UInt64(cpu.cpu_ticks.1) + UInt64(cpu.cpu_ticks.2) + UInt64(cpu.cpu_ticks.3)
            idleTicks += UInt64(cpu.cpu_ticks.2) // CPU_STATE_IDLE
        }

        if previousTotalTicks > 0 {
            let totalDelta = totalTicks - previousTotalTicks
            let idleDelta = idleTicks - previousIdleTicks

            if totalDelta > 0 {
                let usage = Double(totalDelta - idleDelta) / Double(totalDelta) * 100.0
                stats.cpuUsage = min(max(usage, 0.0), 100.0)
            }
        }

        previousTotalTicks = totalTicks
        previousIdleTicks = idleTicks

        let size = MemoryLayout<integer_t>.stride * Int(numCPUInfo)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(size))
    }

    /// “Used” RAM ≈ wired + active + compressor-backed pages (typical third-party approximation
    /// of pressure; **excludes** most inactive file cache). Total is physical RAM. Compare with
    /// Activity Monitor for sanity — numbers may differ by a few GB depending on macOS version.
    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            self.stats.memoryUsage = 0.0
            return
        }

        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let pageSize = UInt64(vm_page_size)

        let usedPages = UInt64(stats.wire_count)
            + UInt64(stats.active_count)
            + UInt64(stats.compressor_page_count)
        let usedMemory = usedPages * pageSize

        let totalGB = Double(totalMemory) / 1_073_741_824.0
        let usedGB = Double(usedMemory) / 1_073_741_824.0

        self.stats.memoryTotalGB = totalGB
        self.stats.memoryUsedGB = usedGB
        self.stats.memoryUsage = totalMemory > 0 ? (Double(usedMemory) / Double(totalMemory)) * 100.0 : 0
    }

    private func updateNetworkStats() {
        let network = networkMonitor.snapshot()
        stats.wifiSSID = network.wifiSSID
        stats.wifiConnected = network.wifiConnected
        stats.localIPAddress = network.localIPAddress
        stats.uploadMbps = network.uploadMbps
        stats.downloadMbps = network.downloadMbps
    }

    private func updateBatteryStats() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  (info[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }

            let current = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = info[kIOPSMaxCapacityKey] as? Int ?? 100
            stats.batteryLevel = max > 0 ? Double(current) / Double(max) * 100.0 : 0.0
            stats.isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
            stats.isPluggedIn = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            return
        }

        stats.batteryLevel = nil
        stats.isCharging = false
        stats.isPluggedIn = false
    }

    private func refreshPublicIPIfNeeded() {
        let now = Date()
        if let last = lastPublicIPLookup, now.timeIntervalSince(last) < 300 {
            return
        }
        lastPublicIPLookup = now

        guard let url = URL(string: "https://api.ipify.org?format=text") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self, let data, let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
            DispatchQueue.main.async {
                self.stats.publicIPAddress = value
            }
        }.resume()
    }

    deinit {
        stopMonitoring()
    }
}
