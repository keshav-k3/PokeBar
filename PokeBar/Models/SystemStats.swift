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
    var localIPAddress: String?
    var publicIPAddress: String?
    var uploadMbps: Double?
    var downloadMbps: Double?

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
        wifiSSID ?? "Not connected"
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
}
