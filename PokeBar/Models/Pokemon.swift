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
    /// Order: regional starter families together (stage 1 → 2 → 3), then other species.
    static let available: [Pokemon] = [
        // Kanto starters
        Pokemon(id: "bulbasaur", name: "Bulbasaur"),
        Pokemon(id: "ivysaur", name: "Ivysaur"),
        Pokemon(id: "venasaur", name: "Venusaur"),
        Pokemon(id: "charmander", name: "Charmander"),
        Pokemon(id: "charmeleon", name: "Charmeleon"),
        Pokemon(id: "charizard", name: "Charizard"),
        Pokemon(id: "squirtle", name: "Squirtle"),
        Pokemon(id: "wartortle", name: "Wartortle"),
        Pokemon(id: "blastoise", name: "Blastoise"),
        Pokemon(id: "pikachu", name: "Pikachu"),
        // Johto starters
        Pokemon(id: "cyndaquil", name: "Cyndaquil"),
        Pokemon(id: "quilava", name: "Quilava"),
        Pokemon(id: "typhlosion", name: "Typhlosion"),
        Pokemon(id: "totodile", name: "Totodile"),
        Pokemon(id: "croconaw", name: "Croconaw"),
        Pokemon(id: "feraligatr", name: "Feraligatr"),
        Pokemon(id: "chikorita", name: "Chikorita"),
        Pokemon(id: "bayleef", name: "Bayleef"),
        Pokemon(id: "meganium", name: "Meganium"),
        // Hoenn starters
        Pokemon(id: "treeko", name: "Treecko"),
        Pokemon(id: "grovyle", name: "Grovyle"),
        Pokemon(id: "sceptile", name: "Sceptile"),
        Pokemon(id: "torchic", name: "Torchic"),
        Pokemon(id: "combusken", name: "Combusken"),
        Pokemon(id: "blaziken", name: "Blaziken"),
        Pokemon(id: "mudkip", name: "Mudkip"),
        Pokemon(id: "marshtomp", name: "Marshtomp"),
        Pokemon(id: "swampert", name: "Swampert"),
        // Sinnoh starters
        Pokemon(id: "turtwig", name: "Turtwig"),
        Pokemon(id: "grotle", name: "Grotle"),
        Pokemon(id: "torterra", name: "Torterra"),
        Pokemon(id: "chimchar", name: "Chimchar"),
        Pokemon(id: "monferno", name: "Monferno"),
        Pokemon(id: "infernape", name: "Infernape"),
        Pokemon(id: "piplup", name: "Piplup"),
        Pokemon(id: "prinplup", name: "Prinplup"),
        Pokemon(id: "empoleon", name: "Empoleon"),
        // Unova starters
        Pokemon(id: "snivy", name: "Snivy"),
        Pokemon(id: "servine", name: "Servine"),
        Pokemon(id: "serperior", name: "Serperior"),
        Pokemon(id: "tepig", name: "Tepig"),
        Pokemon(id: "pignite", name: "Pignite"),
        Pokemon(id: "emboar", name: "Emboar"),
        Pokemon(id: "oshawott", name: "Oshawott"),
        Pokemon(id: "dewott", name: "Dewott"),
        Pokemon(id: "samurott", name: "Samurott"),
        // Other
        Pokemon(id: "jigglypuff", name: "Jigglypuff"),
        Pokemon(id: "psyduck", name: "Psyduck"),
        Pokemon(id: "eevee", name: "Eevee"),
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
