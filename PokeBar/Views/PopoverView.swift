//
//  PopoverView.swift
//  PokeBar
//
//  System stats — frosted “glass” layout; Pokémon picker expands below (same popover).
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var sheet: PopoverSheetState
    @ObservedObject var systemMonitor: SystemMonitor
    @ObservedObject var pokemonManager: PokemonManager
    @ObservedObject var preferences: UserPreferences

    let onQuit: () -> Void
    let onPokemonPicked: () -> Void
    @State private var showLanguageMenu = false
    @State private var pokemonSearchQuery = ""
    @State private var pokeballRotation: Double = 0
    @State private var spinTimer: Timer?

    private let chromeRadius: CGFloat = 14
    private let innerRadius: CGFloat = 10

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                header
                if showLanguageMenu { languageMenu }
                statsSection
            }
            .frame(width: 396)

            if sheet.showPokemonPicker { pokemonPickerSidebar }
        }
        .padding(14)
        .frame(width: sheet.showPokemonPicker ? 840 : 420)
        .background {
            RoundedRectangle(cornerRadius: chromeRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.94, blue: 0.88), Color(red: 0.90, green: 0.89, blue: 0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: chromeRadius, style: .continuous)
                .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.28), lineWidth: 1.2)
        }
        .onChange(of: sheet.showPokemonPicker) { expanded in
            if expanded {
                startPokeballSpin()
            } else {
                stopPokeballSpin()
            }
        }
        .onDisappear {
            stopPokeballSpin()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                if let image = pokemonManager.popoverStaticImage(for: pokemonManager.currentPokemon) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(pokemonManager.currentPokemon.localizedDisplayName(language: preferences.appLanguage))
                        .font(.system(size: 17, weight: .semibold))
                    Text(L10n.tr("popover.systemMonitor", language: preferences.appLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    pokeballHeaderButton
                    iconControlButton(systemName: "gearshape.fill") {
                        showLanguageMenu.toggle()
                    }
                    iconControlButton(systemName: "power") {
                        onQuit()
                    }
                }
            }

            partyRow
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(Color.white.opacity(0.34))
        }
        .overlay {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.18), lineWidth: 1)
        }
    }

    private var partyRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { slot in
                if slot < pokemonManager.party.count {
                    let pokemon = pokemonManager.party[slot]
                    PartySlotView(
                        pokemon: pokemon,
                        isActive: pokemon.id == pokemonManager.currentPokemon.id,
                        image: pokemonManager.previewImage(for: pokemon),
                        onActivate: { pokemonManager.selectPokemon(pokemon) },
                        onRemove: { pokemonManager.removeFromParty(pokemon) }
                    )
                } else {
                    Button { sheet.showPokemonPicker = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.45))
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.22))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.18),
                                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if pokemonManager.party.count > 1 {
                Text(L10n.tr("popover.partyAutoRotate", language: preferences.appLanguage))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.55))
            }
        }
    }

    private var languageMenu: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(L10n.tr("settings.appLanguage", language: preferences.appLanguage))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: $preferences.appLanguage) {
                Text("EN").tag(AppLanguage.english)
                Text("JP").tag(AppLanguage.japanese)
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.14), lineWidth: 1)
        )
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            GlassStatRow(
                icon: "cpu",
                label: L10n.tr("stats.cpu", language: preferences.appLanguage),
                value: systemMonitor.stats.formattedCPU,
                percentage: systemMonitor.stats.cpuUsage,
                accent: .blue,
                history: systemMonitor.cpuHistory
            )
            GlassStatRow(
                icon: "memorychip",
                label: L10n.tr("stats.memory", language: preferences.appLanguage),
                value: systemMonitor.stats.formattedMemory,
                percentage: systemMonitor.stats.memoryPercentage,
                accent: .green,
                history: systemMonitor.memoryHistory
            )
            NetworkCard(stats: systemMonitor.stats, language: preferences.appLanguage)
            if systemMonitor.stats.hasBattery {
                BatteryCard(stats: systemMonitor.stats, language: preferences.appLanguage)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(Color.white.opacity(0.30))
        }
        .overlay {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.14), lineWidth: 1)
        }
    }

    private var pokeballHeaderButton: some View {
        Button {
            sheet.showPokemonPicker.toggle()
        } label: {
            Group {
                if let image = pokeballImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(pokeballRotation))
                } else {
                    Image(systemName: "circle.grid.cross")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.primary.opacity(0.78))
            .background(
                Circle().fill(Color.white.opacity(0.38))
            )
            .overlay(
                Circle().stroke(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func startPokeballSpin() {
        guard spinTimer == nil else { return }
        pokeballRotation = 0
        spinTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            pokeballRotation = (pokeballRotation + 12).truncatingRemainder(dividingBy: 360)
        }
        if let spinTimer {
            RunLoop.main.add(spinTimer, forMode: .common)
        }
    }

    private func stopPokeballSpin() {
        spinTimer?.invalidate()
        spinTimer = nil
        pokeballRotation = 0
    }

    private var pokemonPickerSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("popover.choosePokemon", language: preferences.appLanguage))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField(L10n.tr("popover.searchPokemon", language: preferences.appLanguage), text: $pokemonSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.15), lineWidth: 1)
            )

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredPokemon) { pokemon in
                        embeddedPokemonRow(pokemon)
                    }
                    if filteredPokemon.isEmpty {
                        Text(L10n.tr("popover.noPokemonFound", language: preferences.appLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 396)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(Color.white.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .strokeBorder(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.14), lineWidth: 1)
        )
    }

    private func embeddedPokemonRow(_ pokemon: Pokemon) -> some View {
        let isActive = pokemon.id == pokemonManager.currentPokemon.id
        let isInParty = pokemonManager.isInParty(pokemon)
        let partyFull = pokemonManager.party.count >= 3
        let slot = pokemonManager.partySlot(of: pokemon)
        let slotLabels = ["①", "②", "③"]

        return Button {
            if isInParty {
                pokemonManager.selectPokemon(pokemon)
                sheet.showPokemonPicker = false
                onPokemonPicked()
            } else if !partyFull {
                pokemonManager.addToParty(pokemon)
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                    if let image = pokemonManager.previewImage(for: pokemon) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipped()
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .opacity((!isInParty && partyFull) ? 0.45 : 1.0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pokemon.localizedDisplayName(language: preferences.appLanguage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(pokemon.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .opacity((!isInParty && partyFull) ? 0.45 : 1.0)

                Spacer()

                if let slot = slot {
                    Text(slotLabels[slot])
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isActive ? Color.accentColor : Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.75))
                } else if !partyFull {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isActive ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.09),
                        lineWidth: isActive ? 1.8 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isInParty && partyFull)
    }

    private var filteredPokemon: [Pokemon] {
        let query = pokemonSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return Pokemon.available }
        return Pokemon.available.filter { pokemon in
            pokemon.name.lowercased().contains(query)
                || pokemon.id.lowercased().contains(query)
                || pokemon.localizedDisplayName(language: preferences.appLanguage).lowercased().contains(query)
        }
    }

    private func iconControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.primary.opacity(0.78))
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.38))
                )
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.44, green: 0.30, blue: 0.42).opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var pokeballImage: NSImage? {
        var candidates: [String] = []
        if let resourcePath = Bundle.main.resourcePath {
            candidates.append("\(resourcePath)/pokeball.png")
            candidates.append("\(resourcePath)/PokeBar_PokeBar.bundle/Resources/pokeball.png")
            candidates.append("\(resourcePath)/Resources/pokeball.png")
        }
        if let executablePath = Bundle.main.executableURL?.deletingLastPathComponent().path {
            candidates.append("\(executablePath)/PokeBar_PokeBar.bundle/Resources/pokeball.png")
        }
        candidates.append(FileManager.default.currentDirectoryPath + "/PokeBar/Resources/pokeball.png")
        for path in candidates {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}

private struct NetworkCard: View {
    let stats: SystemStats
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L10n.tr("stats.network", language: language), systemImage: "wifi")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(stats.formattedNetworkName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(L10n.tr("stats.publicIp", language: language))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(stats.formattedPublicIP)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                transferTile(
                    icon: "arrow.down.circle.fill",
                    title: L10n.tr("stats.download", language: language),
                    value: stats.formattedDownloadSpeed,
                    accent: .blue
                )
                transferTile(
                    icon: "arrow.up.circle.fill",
                    title: L10n.tr("stats.upload", language: language),
                    value: stats.formattedUploadSpeed,
                    accent: .green
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func transferTile(icon: String, title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

private struct PartySlotView: View {
    let pokemon: Pokemon
    let isActive: Bool
    let image: NSImage?
    let onActivate: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    private let purple = Color(red: 0.44, green: 0.30, blue: 0.42)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onActivate) {
                ZStack {
                    if let img = image {
                        Image(nsImage: img)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                    }
                }
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            isActive ? Color.accentColor.opacity(0.85) : purple.opacity(0.22),
                            lineWidth: isActive ? 1.5 : 1
                        )
                )
            }
            .buttonStyle(.plain)

            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
        .onHover { isHovering = $0 }
    }
}

private struct BatteryCard: View {
    let stats: SystemStats
    let language: AppLanguage

    private var level: Double { stats.batteryLevel ?? 0 }

    private var accent: Color {
        if level > 50 { return .green }
        if level > 20 { return .orange }
        return .red
    }

    private var statusText: String {
        if stats.isCharging {
            return L10n.tr("stats.batteryCharging", language: language)
        }
        return stats.isPluggedIn
            ? L10n.tr("stats.batteryPluggedIn", language: language)
            : L10n.tr("stats.batteryOnBattery", language: language)
    }

    private var statusIcon: String {
        if stats.isCharging { return "bolt.fill" }
        return stats.isPluggedIn ? "powerplug.fill" : "battery.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(L10n.tr("stats.battery", language: language), systemImage: "battery.100")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(stats.isCharging ? .yellow : .secondary)
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 7)
                        Capsule()
                            .fill(accent.opacity(0.9))
                            .frame(width: max(4, geo.size.width * (level / 100.0)), height: 7)
                            .animation(.easeInOut(duration: 0.28), value: level)
                    }
                }
                .frame(height: 7)

                Text(stats.formattedBattery)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accent)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

private struct GlassStatRow: View {
    let icon: String
    let label: String
    let value: String
    let percentage: Double
    let accent: Color
    var history: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 22, alignment: .center)

                Text(label)
                    .font(.system(size: 13, weight: .semibold))

                Spacer(minLength: 0)

                Text(value)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 7)
                    Capsule()
                        .fill(accent.opacity(0.9))
                        .frame(width: max(4, geo.size.width * (percentage / 100.0)), height: 7)
                        .animation(.easeInOut(duration: 0.28), value: percentage)
                }
            }
            .frame(height: 7)

            if history.count > 1 {
                MiniLineChart(data: history, accent: accent)
                    .frame(height: 36)
            }
        }
    }
}


private struct MiniLineChart: View {
    let data: [Double]
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxVal = max(data.max() ?? 1, 1)
            let step = data.count > 1 ? w / CGFloat(data.count - 1) : 0

            ZStack(alignment: .topLeading) {
                // Horizontal grid lines at 25%, 50%, 75%
                ForEach([0.25, 0.5, 0.75], id: \.self) { frac in
                    Path { path in
                        let y = h - h * CGFloat(frac * 100.0 / maxVal)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                }

                // Filled area
                Path { path in
                    guard data.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: h))
                    for (i, val) in data.enumerated() {
                        let x = step * CGFloat(i)
                        let y = h - h * CGFloat(val / maxVal)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: step * CGFloat(data.count - 1), y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.25), accent.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard data.count > 1 else { return }
                    for (i, val) in data.enumerated() {
                        let x = step * CGFloat(i)
                        let y = h - h * CGFloat(val / maxVal)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(accent.opacity(0.8), lineWidth: 1.2)
            }
            .clipped()
        }
    }
}
