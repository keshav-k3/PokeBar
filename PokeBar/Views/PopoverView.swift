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

    private let chromeRadius: CGFloat = 14
    private let innerRadius: CGFloat = 10

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            statsSection
            buttonRow

            if sheet.showPokemonPicker {
                pokemonPickerSection
            }
        }
        .padding(14)
        .frame(width: 388)
        .background {
            RoundedRectangle(cornerRadius: chromeRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: chromeRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private var header: some View {
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
            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
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
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 10) {
            glassButton(
                title: sheet.showPokemonPicker
                    ? L10n.tr("common.done", language: preferences.appLanguage)
                    : L10n.tr("popover.changePokemon", language: preferences.appLanguage),
                prominent: true,
                action: {
                    sheet.showPokemonPicker.toggle()
                }
            )
            glassButton(title: L10n.tr("menu.quit", language: preferences.appLanguage), prominent: false, action: onQuit)
        }
    }

    private var pokemonPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("popover.choosePokemon", language: preferences.appLanguage))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(Pokemon.available) { pokemon in
                        embeddedPokemonCell(pokemon)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .padding(.top, 4)
    }

    private func embeddedPokemonCell(_ pokemon: Pokemon) -> some View {
        let selected = pokemon.id == pokemonManager.currentPokemon.id
        return Button {
            pokemonManager.selectPokemon(pokemon)
            sheet.showPokemonPicker = false
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                    if let image = pokemonManager.previewImage(for: pokemon) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipped()
                    }
                }
                .frame(height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(pokemon.localizedDisplayName(language: preferences.appLanguage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.22) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selected ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.1),
                        lineWidth: selected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func glassButton(title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(prominent ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06))
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(prominent ? 0.15 : 0.1), lineWidth: 1)
        }
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
