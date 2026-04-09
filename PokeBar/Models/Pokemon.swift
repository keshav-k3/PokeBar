//
//  Pokemon.swift
//  PokeBar
//
//  Pokemon data model
//

import Foundation

struct Pokemon: Identifiable, Codable, Equatable {
    let id: String
    let name: String

    /// Available roster (menu bar = sleep sheet PNG frames; popover = static PNG).
    static let available: [Pokemon] = [
        Pokemon(id: "pikachu", name: "Pikachu"),
        Pokemon(id: "charmander", name: "Charmander"),
        Pokemon(id: "squirtle", name: "Squirtle"),
        Pokemon(id: "bulbasaur", name: "Bulbasaur"),
        Pokemon(id: "jigglypuff", name: "Jigglypuff"),
        Pokemon(id: "psyduck", name: "Psyduck"),
        Pokemon(id: "eevee", name: "Eevee"),
        Pokemon(id: "oshawott", name: "Oshawott"),
        Pokemon(id: "dragonite", name: "Dragonite"),
        Pokemon(id: "snorlax", name: "Snorlax")
    ]

    static var `default`: Pokemon {
        available[0]
    }

    /// Horizontal strip in `Resources/Sprites` (layout matches `SleepSheetFrameDecoder`).
    var menubarSleepSheetFilename: String {
        "Sleep-Anim-\(id).png"
    }

    /// `Resources/Sprites/Static-<id>.png` — crisp art for popover + picker.
    var popoverStaticImageFilename: String {
        "Static-\(id).png"
    }

    func localizedDisplayName(language: AppLanguage) -> String {
        L10n.pokemonName(id: id, language: language)
    }
}
