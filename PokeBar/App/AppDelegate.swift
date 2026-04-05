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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menubar-only app
        NSApp.setActivationPolicy(.accessory)

        systemMonitor = SystemMonitor()
        pokemonManager = PokemonManager()

        pokemonManager?.onPokemonSelectionChanged = { [weak self] _ in
            self?.menuBarController?.reloadMenubarAnimation()
        }

        menuBarController = MenuBarController(
            systemMonitor: systemMonitor!,
            pokemonManager: pokemonManager!
        )
        menuBarController?.reloadMenubarAnimation()

        systemMonitor?.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.teardown()
        systemMonitor?.stopMonitoring()
    }
}
