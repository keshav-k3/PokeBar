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
    private let preferences = UserPreferences()

    /// Fired after the user selects a different Pokémon (and on programmatic changes).
    var onPokemonSelectionChanged: ((Pokemon) -> Void)?

    init() {
        let savedID = preferences.selectedPokemon
        if let pokemon = Pokemon.available.first(where: { $0.id == savedID }) {
            currentPokemon = pokemon
        } else {
            currentPokemon = Pokemon.default
            preferences.selectedPokemon = currentPokemon.id
        }
    }

    func selectPokemon(_ pokemon: Pokemon) {
        currentPokemon = pokemon
        preferences.selectedPokemon = pokemon.id
        onPokemonSelectionChanged?(pokemon)
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
        guard let url = urlForSprite(named: name) else { return nil }
        return NSImage(contentsOf: url)
    }
}
