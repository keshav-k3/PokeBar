//
//  NetworkMonitor.swift
//  PokeBar
//
//  Wi-Fi and network throughput sampling.
//

import Foundation
import CoreWLAN
import Darwin

struct NetworkSnapshot {
    let wifiSSID: String?
    let wifiConnected: Bool
    let localIPAddress: String?
    let uploadMbps: Double?
    let downloadMbps: Double?
}

final class NetworkMonitor {
    private var previousInBytes: UInt64?
    private var previousOutBytes: UInt64?
    private var previousSampleDate: Date?
    private var cachedFallbackSSID: String?
    private var lastFallbackSSIDLookup: Date?

    func snapshot() -> NetworkSnapshot {
        let now = Date()
        let interfaces = CWWiFiClient.shared().interfaces() ?? []
        let coreWlanSSID = interfaces.compactMap { $0.ssid() }.first
        let ssid = sanitizeSSID(coreWlanSSID) ?? fallbackSSID(now: now)
        let ip = currentLocalIPAddress()
        let counters = interfaceByteCounters()
        let wifiConnected = ssid != nil || (interfaces.contains { $0.powerOn() } && ip != nil)

        var upload: Double?
        var download: Double?
        if let counters,
           let prevIn = previousInBytes,
           let prevOut = previousOutBytes,
           let prevDate = previousSampleDate {
            let elapsed = now.timeIntervalSince(prevDate)
            if elapsed > 0 {
                let inDelta = counters.inBytes >= prevIn ? counters.inBytes - prevIn : 0
                let outDelta = counters.outBytes >= prevOut ? counters.outBytes - prevOut : 0
                download = (Double(inDelta) * 8.0) / elapsed / 1_000_000.0
                upload = (Double(outDelta) * 8.0) / elapsed / 1_000_000.0
            }
        }

        if let counters {
            previousInBytes = counters.inBytes
            previousOutBytes = counters.outBytes
        }
        previousSampleDate = now

        return NetworkSnapshot(
            wifiSSID: ssid,
            wifiConnected: wifiConnected,
            localIPAddress: ip,
            uploadMbps: upload,
            downloadMbps: download
        )
    }

    private func currentLocalIPAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ptr = cursor {
            let interface = ptr.pointee
            let family = interface.ifa_addr.pointee.sa_family
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            let name = String(cString: interface.ifa_name)

            if family == UInt8(AF_INET), isUp, !isLoopback, name.hasPrefix("en") {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                if result == 0 { return String(cString: host) }
            }

            cursor = interface.ifa_next
        }
        return nil
    }

    private func interfaceByteCounters() -> (inBytes: UInt64, outBytes: UInt64)? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var found = false

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ptr = cursor {
            let interface = ptr.pointee
            let family = interface.ifa_addr.pointee.sa_family
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            let name = String(cString: interface.ifa_name)

            if family == UInt8(AF_LINK), isUp, !isLoopback, (name.hasPrefix("en") || name.hasPrefix("pdp_ip")),
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                totalIn += UInt64(data.ifi_ibytes)
                totalOut += UInt64(data.ifi_obytes)
                found = true
            }

            cursor = interface.ifa_next
        }

        return found ? (totalIn, totalOut) : nil
    }

    private func fallbackSSID(now: Date) -> String? {
        // Avoid spawning subprocesses every 1s monitor tick.
        if let last = lastFallbackSSIDLookup, now.timeIntervalSince(last) < 15 {
            return cachedFallbackSSID
        }
        lastFallbackSSIDLookup = now

        if let ssid = fallbackSSIDFromAirportTool() {
            let clean = sanitizeSSID(ssid)
            cachedFallbackSSID = clean
            return clean
        }

        if let ssid = fallbackSSIDFromNetworkSetup() {
            let clean = sanitizeSSID(ssid)
            cachedFallbackSSID = clean
            return clean
        }

        if let ssid = fallbackSSIDFromIPConfigSummary() {
            let clean = sanitizeSSID(ssid)
            cachedFallbackSSID = clean
            return clean
        }

        cachedFallbackSSID = nil
        return nil
    }

    private func fallbackSSIDFromAirportTool() -> String? {
        let airportCandidates = [
            "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport",
            "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport"
        ]
        guard let airportPath = airportCandidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: airportPath)
        process.arguments = ["-I"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }

        let ssidLine = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix("SSID:") && !$0.hasPrefix("SSID BSSID:") }

        let ssid = ssidLine?
            .replacingOccurrences(of: "SSID:", with: "")
            .trimmingCharacters(in: .whitespaces)
        return (ssid?.isEmpty == false) ? ssid : nil
    }

    private func fallbackSSIDFromNetworkSetup() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-getairportnetwork", "en0"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              text.hasPrefix("Current Wi-Fi Network:") else {
            return nil
        }
        let ssid = text.replacingOccurrences(of: "Current Wi-Fi Network:", with: "")
            .trimmingCharacters(in: .whitespaces)
        return ssid.isEmpty ? nil : ssid
    }

    private func fallbackSSIDFromIPConfigSummary() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ipconfig")
        process.arguments = ["getsummary", "en0"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return nil }

        let ssidLine = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix("SSID :") || $0.hasPrefix("SSID:") }

        guard let ssidLine else { return nil }
        let ssid = ssidLine
            .replacingOccurrences(of: "SSID :", with: "")
            .replacingOccurrences(of: "SSID:", with: "")
            .trimmingCharacters(in: .whitespaces)
        return ssid.isEmpty ? nil : ssid
    }

    private func sanitizeSSID(_ ssid: String?) -> String? {
        guard let raw = ssid?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        let lowered = raw.lowercased()
        let blockedValues: Set<String> = ["<redacted>", "redacted", "<hidden>", "hidden", "<private>"]
        return blockedValues.contains(lowered) ? nil : raw
    }
}
