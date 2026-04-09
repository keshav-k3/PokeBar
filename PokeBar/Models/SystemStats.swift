//
//  SystemStats.swift
//  PokeBar
//
//  System statistics data model
//

import Foundation

struct SystemStats {
    var cpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var memoryUsedGB: Double = 0.0
    var memoryTotalGB: Double = 0.0
    var diskReadMBps: Double = 0.0
    var diskWriteMBps: Double = 0.0
    var wifiSSID: String?
    var wifiConnected: Bool = false
    var localIPAddress: String?
    var publicIPAddress: String?
    var uploadMbps: Double?
    var downloadMbps: Double?
    var batteryLevel: Double? // 0–100, nil if no battery
    var isCharging: Bool = false
    var isPluggedIn: Bool = false

    var memoryPercentage: Double {
        guard memoryTotalGB > 0 else { return 0 }
        return (memoryUsedGB / memoryTotalGB) * 100
    }

    var formattedCPU: String {
        String(format: "%.1f%%", cpuUsage)
    }

    var formattedMemory: String {
        String(format: "%.1f / %.1f GB", memoryUsedGB, memoryTotalGB)
    }

    var formattedMemoryPercentage: String {
        String(format: "%.0f%%", memoryPercentage)
    }

    var formattedNetworkName: String {
        wifiConnected ? "Connected" : "Not connected"
    }

    var formattedLocalIP: String {
        localIPAddress ?? "Unavailable"
    }

    var formattedPublicIP: String {
        publicIPAddress ?? "Unavailable"
    }

    var formattedUploadSpeed: String {
        guard let uploadMbps else { return "—" }
        return String(format: "%.2f Mbps", max(uploadMbps, 0))
    }

    var formattedDownloadSpeed: String {
        guard let downloadMbps else { return "—" }
        return String(format: "%.2f Mbps", max(downloadMbps, 0))
    }

    var hasBattery: Bool { batteryLevel != nil }

    var formattedBattery: String {
        guard let level = batteryLevel else { return "—" }
        return String(format: "%.0f%%", level)
    }
}
