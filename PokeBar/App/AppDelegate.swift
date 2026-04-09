//
//  AppDelegate.swift
//  PokeBar
//
//  Application delegate managing menubar lifecycle
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var systemMonitor: SystemMonitor?
    private var pokemonManager: PokemonManager?
    private let preferences = UserPreferences.shared
    private let updater = UpdaterService.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menubar-only app
        NSApp.setActivationPolicy(preferences.showInDock ? .regular : .accessory)

        systemMonitor = SystemMonitor(updateInterval: preferences.updateInterval)
        pokemonManager = PokemonManager(preferences: preferences)

        pokemonManager?.onPokemonSelectionChanged = { [weak self] _ in
            self?.menuBarController?.reloadMenubarAnimation()
        }

        menuBarController = MenuBarController(
            systemMonitor: systemMonitor!,
            pokemonManager: pokemonManager!,
            preferences: preferences,
            onCheckUpdates: { [weak self] in
                self?.updater.checkForUpdates()
            }
        )
        menuBarController?.reloadMenubarAnimation()

        systemMonitor?.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.teardown()
        systemMonitor?.stopMonitoring()
    }
}
