//
//  UserPreferences.swift
//  PokeBar
//
//  User preferences with UserDefaults persistence
//

import Foundation

class UserPreferences: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedPokemon = "selectedPokemon"
        static let launchAtLogin = "launchAtLogin"
        static let showInDock = "showInDock"
        static let updateInterval = "updateInterval"
        static let enableNotifications = "enableNotifications"
    }

    @Published var selectedPokemon: String {
        didSet {
            defaults.set(selectedPokemon, forKey: Keys.selectedPokemon)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        }
    }

    @Published var showInDock: Bool {
        didSet {
            defaults.set(showInDock, forKey: Keys.showInDock)
        }
    }

    @Published var updateInterval: Double {
        didSet {
            defaults.set(updateInterval, forKey: Keys.updateInterval)
        }
    }

    @Published var enableNotifications: Bool {
        didSet {
            defaults.set(enableNotifications, forKey: Keys.enableNotifications)
        }
    }

    init() {
        self.selectedPokemon = defaults.string(forKey: Keys.selectedPokemon) ?? "pikachu"
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.updateInterval = defaults.double(forKey: Keys.updateInterval) != 0 ? defaults.double(forKey: Keys.updateInterval) : 1.0
        self.enableNotifications = defaults.bool(forKey: Keys.enableNotifications)
    }
}
