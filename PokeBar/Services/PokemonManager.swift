//
//  PokemonManager.swift
//  PokeBar
//
//  Pokemon selection and management service
//

import Foundation
import AppKit

class PokemonManager: ObservableObject {
    @Published var currentPokemon: Pokemon
    private let preferences: UserPreferences
    private var staticImageCache: [String: NSImage] = [:]
    private var rotationTimer: Timer?
    private static let rotationInterval: TimeInterval = 60.0

    /// Fired after the user selects a different Pokémon (and on programmatic changes).
    var onPokemonSelectionChanged: ((Pokemon) -> Void)?

    init(preferences: UserPreferences = .shared) {
        self.preferences = preferences
        let savedID = preferences.selectedPokemon
        if let pokemon = Pokemon.available.first(where: { $0.id == savedID }) {
            currentPokemon = pokemon
        } else {
            currentPokemon = Pokemon.default
            preferences.selectedPokemon = currentPokemon.id
        }
        scheduleRotationIfNeeded()
    }

    func selectPokemon(_ pokemon: Pokemon) {
        currentPokemon = pokemon
        preferences.selectedPokemon = pokemon.id
        onPokemonSelectionChanged?(pokemon)
    }

    // MARK: - Party

    var party: [Pokemon] {
        preferences.pokemonParty.compactMap { id in
            Pokemon.available.first(where: { $0.id == id })
        }
    }

    func isInParty(_ pokemon: Pokemon) -> Bool {
        preferences.pokemonParty.contains(pokemon.id)
    }

    func partySlot(of pokemon: Pokemon) -> Int? {
        preferences.pokemonParty.firstIndex(of: pokemon.id)
    }

    func addToParty(_ pokemon: Pokemon) {
        guard !isInParty(pokemon), preferences.pokemonParty.count < 3 else { return }
        preferences.pokemonParty.append(pokemon.id)
        scheduleRotationIfNeeded()
        objectWillChange.send()
    }

    func removeFromParty(_ pokemon: Pokemon) {
        guard preferences.pokemonParty.count > 1 else { return }
        preferences.pokemonParty.removeAll { $0 == pokemon.id }
        if currentPokemon.id == pokemon.id, let first = party.first {
            selectPokemon(first)
        }
        scheduleRotationIfNeeded()
        objectWillChange.send()
    }

    private func scheduleRotationIfNeeded() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        guard preferences.pokemonParty.count > 1 else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: Self.rotationInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.rotateToNext() }
        }
        RunLoop.main.add(timer, forMode: .common)
        rotationTimer = timer
    }

    private func rotateToNext() {
        let p = party
        guard p.count > 1,
              let idx = p.firstIndex(where: { $0.id == currentPokemon.id }) else { return }
        selectPokemon(p[(idx + 1) % p.count])
    }

    /// URL to a file in `Resources/Sprites` inside the app or dev tree.
    func urlForSprite(named filename: String) -> URL? {
        // Avoid Bundle.module directly: its generated accessor traps if the helper bundle is missing.
        // Search the helper bundle and direct app resource layouts defensively.
        let fm = FileManager.default
        var candidatePaths: [String] = []
        if let resourcePath = Bundle.main.resourcePath {
            // SwiftPM helper bundle packaged under Contents/Resources.
            candidatePaths.append("\(resourcePath)/PokeBar_PokeBar.bundle/Resources/Sprites/\(filename)")
            // Direct Resources layout (preferred for packaged app).
            candidatePaths.append("\(resourcePath)/Sprites/\(filename)")
            // Nested Resources/Resources layout (current create-dmg.sh copy behavior).
            candidatePaths.append("\(resourcePath)/Resources/Sprites/\(filename)")
        }
        if let executablePath = Bundle.main.executableURL?.deletingLastPathComponent().path {
            // SwiftPM helper bundle placed next to executable (older/local packaging scripts).
            candidatePaths.append("\(executablePath)/PokeBar_PokeBar.bundle/Resources/Sprites/\(filename)")
        }

        for path in candidatePaths where fm.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        let directPath = fm.currentDirectoryPath
            + "/PokeBar/Resources/Sprites/\(filename)"
        if fm.fileExists(atPath: directPath) {
            return URL(fileURLWithPath: directPath)
        }

        return nil
    }

    func urlForMenubarSleepSheet(of pokemon: Pokemon) -> URL? {
        urlForSprite(named: pokemon.menubarSleepSheetFilename)
    }

    /// Static artwork for popover header and picker tiles.
    func popoverStaticImage(for pokemon: Pokemon) -> NSImage? {
        loadImage(named: pokemon.popoverStaticImageFilename)
    }

    /// Picker: prefer static PNG; else first sleep-sheet frame.
    func previewImage(for pokemon: Pokemon) -> NSImage? {
        if let img = popoverStaticImage(for: pokemon) { return img }
        if let sheetURL = urlForMenubarSleepSheet(of: pokemon),
           let decoded = SleepSheetFrameDecoder.decode(url: sheetURL),
           let first = decoded.frames.first {
            return first
        }
        return nil
    }

    private func loadImage(named name: String) -> NSImage? {
        if let cached = staticImageCache[name] {
            return cached
        }
        guard let url = urlForSprite(named: name) else { return nil }
        guard let image = NSImage(contentsOf: url) else { return nil }
        staticImageCache[name] = image
        return image
    }
}
