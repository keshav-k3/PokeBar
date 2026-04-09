//
//  UpdaterService.swift
//  PokeBar
//
//  Sparkle integration wrapper.
//

import Foundation
import AppKit
#if canImport(Sparkle)
import Sparkle
#endif

final class UpdaterService {
    static let shared = UpdaterService()

    #if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController
    #endif

    private init() {
        #if canImport(Sparkle)
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        #endif
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        controller.checkForUpdates(nil)
        #else
        guard let url = URL(string: "https://github.com/keshav-k3/PokeBar/releases/latest") else { return }
        NSWorkspace.shared.open(url)
        #endif
    }
}
