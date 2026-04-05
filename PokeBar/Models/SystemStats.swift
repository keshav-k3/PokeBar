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
}
