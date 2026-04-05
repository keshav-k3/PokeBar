//
//  PokeBarApp.swift
//  PokeBar
//
//  Main application entry point
//

import SwiftUI

@main
struct PokeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
