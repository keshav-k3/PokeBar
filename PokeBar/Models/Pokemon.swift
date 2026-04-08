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
    let displayName: String

    /// Available roster (menu bar = sleep sheet PNG frames; popover = static PNG).
    static let available: [Pokemon] = [
        Pokemon(id: "pikachu", name: "Pikachu", displayName: "Pikachu"),
        Pokemon(id: "charmander", name: "Charmander", displayName: "Charmander"),
        Pokemon(id: "squirtle", name: "Squirtle", displayName: "Squirtle"),
        Pokemon(id: "bulbasaur", name: "Bulbasaur", displayName: "Bulbasaur"),
        Pokemon(id: "jigglypuff", name: "Jigglypuff", displayName: "Jigglypuff"),
        Pokemon(id: "psyduck", name: "Psyduck", displayName: "Psyduck"),
        Pokemon(id: "eevee", name: "Eevee", displayName: "Eevee"),
        Pokemon(id: "oshawott", name: "Oshawott", displayName: "Oshawott"),
        Pokemon(id: "dragonite", name: "Dragonite", displayName: "Dragonite"),
        Pokemon(id: "snorlax", name: "Snorlax", displayName: "Snorlax")
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
}
