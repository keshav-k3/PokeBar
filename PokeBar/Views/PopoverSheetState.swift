//
//  PopoverSheetState.swift
//  PokeBar
//
//  Shared UI state between AppKit (menu) and SwiftUI popover.
//

import Combine
import Foundation

final class PopoverSheetState: ObservableObject {
    /// When true, the Pokémon grid is shown below the stats inside the same popover.
    @Published var showPokemonPicker = false
}
