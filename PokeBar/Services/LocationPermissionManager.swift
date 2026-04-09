//
//  LocationPermissionManager.swift
//  PokeBar
//
//  Requests location authorization needed for SSID visibility on modern macOS.
//

import Foundation
import CoreLocation

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermissionIfNeeded() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // No-op: monitor re-reads SSID on its regular polling loop.
    }
}
