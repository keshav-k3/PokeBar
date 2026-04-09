//
//  UserPreferences.swift
//  PokeBar
//
//  User preferences with UserDefaults persistence
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedPokemon = "selectedPokemon"
        static let launchAtLogin = "launchAtLogin"
        static let showInDock = "showInDock"
        static let updateInterval = "updateInterval"
        static let enableNotifications = "enableNotifications"
        static let appLanguage = "appLanguage"
        static let pokemonParty = "pokemonParty"
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

    @Published var appLanguage: AppLanguage {
        didSet {
            defaults.set(appLanguage.rawValue, forKey: Keys.appLanguage)
        }
    }

    @Published var pokemonParty: [String] {
        didSet {
            defaults.set(pokemonParty, forKey: Keys.pokemonParty)
        }
    }

    init() {
        let savedPokemon = defaults.string(forKey: Keys.selectedPokemon) ?? "pikachu"
        self.selectedPokemon = savedPokemon
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showInDock = defaults.bool(forKey: Keys.showInDock)
        self.updateInterval = defaults.double(forKey: Keys.updateInterval) != 0 ? defaults.double(forKey: Keys.updateInterval) : 1.0
        self.enableNotifications = defaults.bool(forKey: Keys.enableNotifications)
        self.appLanguage = AppLanguage(rawValue: defaults.string(forKey: Keys.appLanguage) ?? AppLanguage.english.rawValue) ?? .english
        self.pokemonParty = defaults.stringArray(forKey: Keys.pokemonParty) ?? [savedPokemon]
    }
}
