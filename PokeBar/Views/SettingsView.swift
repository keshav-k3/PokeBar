//
//  SettingsView.swift
//  PokeBar
//
//  Settings and preferences view
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences

    init(preferences: UserPreferences = .shared) {
        self.preferences = preferences
    }

    var body: some View {
        TabView {
            Form {
                Section(header: Text(L10n.tr("settings.general", language: preferences.appLanguage)).font(.headline)) {
                    Toggle(L10n.tr("settings.launchAtLogin", language: preferences.appLanguage), isOn: $preferences.launchAtLogin)
                        .help(L10n.tr("settings.launchAtLoginHelp", language: preferences.appLanguage))

                    Toggle(L10n.tr("settings.showInDock", language: preferences.appLanguage), isOn: $preferences.showInDock)
                        .help(L10n.tr("settings.showInDockHelp", language: preferences.appLanguage))
                        .onChange(of: preferences.showInDock) { newValue in
                            updateDockVisibility(newValue)
                        }
                }

                Section(header: Text(L10n.tr("settings.performance", language: preferences.appLanguage)).font(.headline)) {
                    HStack {
                        Text(L10n.tr("settings.updateInterval", language: preferences.appLanguage))
                        Spacer()
                        Text("\(Int(preferences.updateInterval))s")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $preferences.updateInterval, in: 0.5...5.0, step: 0.5)
                        .help(L10n.tr("settings.updateIntervalHelp", language: preferences.appLanguage))
                }

                Section(header: Text(L10n.tr("settings.notifications", language: preferences.appLanguage)).font(.headline)) {
                    Toggle(L10n.tr("settings.enableNotifications", language: preferences.appLanguage), isOn: $preferences.enableNotifications)
                        .help(L10n.tr("settings.enableNotificationsHelp", language: preferences.appLanguage))
                        .disabled(true)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("PokeBar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version 2.1.0")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(L10n.tr("settings.tagline", language: preferences.appLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
            }
            .padding()
            .tabItem {
                Label(L10n.tr("settings.generalTab", language: preferences.appLanguage), systemImage: "gearshape")
            }

            Form {
                Section(header: Text(L10n.tr("settings.language", language: preferences.appLanguage)).font(.headline)) {
                    Picker(L10n.tr("settings.appLanguage", language: preferences.appLanguage), selection: $preferences.appLanguage) {
                        Text("English").tag(AppLanguage.english)
                        Text("日本語").tag(AppLanguage.japanese)
                    }
                    .pickerStyle(.segmented)
                    .help(L10n.tr("settings.appLanguageHelp", language: preferences.appLanguage))
                }
            }
            .padding()
            .tabItem {
                Label(L10n.tr("settings.languageTab", language: preferences.appLanguage), systemImage: "globe")
            }
        }
        .frame(width: 520, height: 380)
    }

    private func updateDockVisibility(_ showInDock: Bool) {
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }
}
