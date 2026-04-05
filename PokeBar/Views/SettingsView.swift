//
//  SettingsView.swift
//  PokeBar
//
//  Settings and preferences view
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var preferences = UserPreferences()

    var body: some View {
        Form {
            Section(header: Text("General").font(.headline)) {
                Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
                    .help("Automatically start PokeBar when you log in")

                Toggle("Show in Dock", isOn: $preferences.showInDock)
                    .help("Show the application icon in the Dock")
                    .onChange(of: preferences.showInDock) { newValue in
                        updateDockVisibility(newValue)
                    }
            }

            Section(header: Text("Performance").font(.headline)) {
                HStack {
                    Text("Update Interval")
                    Spacer()
                    Text("\(Int(preferences.updateInterval))s")
                        .foregroundColor(.secondary)
                }

                Slider(value: $preferences.updateInterval, in: 0.5...5.0, step: 0.5)
                    .help("How often to update system statistics (lower = more CPU usage)")
            }

            Section(header: Text("Notifications").font(.headline)) {
                Toggle("Enable Notifications", isOn: $preferences.enableNotifications)
                    .help("Show notifications for high resource usage (future feature)")
                    .disabled(true) // Disabled for MVP
            }

            Spacer()

            // App Info
            VStack(spacing: 4) {
                Text("PokeBar")
                    .font(.system(size: 14, weight: .semibold))
                Text("Version 1.0.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("A Pokemon-themed system monitor")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func updateDockVisibility(_ showInDock: Bool) {
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }
}
