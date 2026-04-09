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
    let localIPAddress: String?
    let uploadMbps: Double?
    let downloadMbps: Double?
}

final class NetworkMonitor {
    private var previousInBytes: UInt64?
    private var previousOutBytes: UInt64?
    private var previousSampleDate: Date?

    func snapshot() -> NetworkSnapshot {
        let now = Date()
        let ssid = CWWiFiClient.shared().interface()?.ssid()
        let ip = currentLocalIPAddress()
        let counters = interfaceByteCounters()

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
}
