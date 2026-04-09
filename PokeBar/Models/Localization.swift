//
//  Localization.swift
//  PokeBar
//
//  App-local language selection helpers.
//

import Foundation

enum L10n {
    static func tr(_ key: String, language: AppLanguage) -> String {
        for base in candidateResourceBases() {
            let localizedPath = "\(base)/Localization/\(language.rawValue).lproj"
            if let bundle = Bundle(path: localizedPath) {
                let value = bundle.localizedString(forKey: key, value: key, table: "Localizable")
                if value != key {
                    return value
                }
            }
        }
        return key
    }

    static func pokemonName(id: String, language: AppLanguage) -> String {
        tr("pokemon.\(id)", language: language)
    }

    private static func candidateResourceBases() -> [String] {
        var bases: [String] = []
        if let mainResource = Bundle.main.resourcePath {
            bases.append(mainResource)
            // SwiftPM helper bundle layout.
            bases.append("\(mainResource)/PokeBar_PokeBar.bundle/Resources")
        }
        if let exec = Bundle.main.executableURL?.deletingLastPathComponent().path {
            bases.append("\(exec)/PokeBar_PokeBar.bundle/Resources")
        }
        bases.append(FileManager.default.currentDirectoryPath + "/PokeBar/Resources")
        return Array(Set(bases))
    }
}
