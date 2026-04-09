//
//  MenuBarController.swift
//  PokeBar
//
//  Manages the menubar icon and popover
//

import Cocoa
import Combine
import SwiftUI

class MenuBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private let systemMonitor: SystemMonitor
    private let pokemonManager: PokemonManager
    private let preferences: UserPreferences
    private let onCheckUpdates: () -> Void
    private let popoverSheet = PopoverSheetState()
    private var popoverSizeCancellable: AnyCancellable?

    private var menubarFrames: [NSImage] = []
    private var menubarDelays: [TimeInterval] = []
    private var menubarFrameIndex: Int = 0
    private var menubarAnimTimer: Timer?
    private var outsideClickMonitor: Any?
    private var resignActiveObserver: NSObjectProtocol?

    init(
        systemMonitor: SystemMonitor,
        pokemonManager: PokemonManager,
        preferences: UserPreferences = .shared,
        onCheckUpdates: @escaping () -> Void
    ) {
        self.systemMonitor = systemMonitor
        self.pokemonManager = pokemonManager
        self.preferences = preferences
        self.onCheckUpdates = onCheckUpdates
        super.init()

        setupMenuBar()
        setupPopover()
        wirePopoverContentSize()

        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.popover?.isShown == true else { return }
            self.popover?.performClose(nil)
        }
    }

    deinit {
        invalidateMenubarAnimTimer()
        stopOutsideClickMonitor()
        popoverSizeCancellable?.cancel()
        if let obs = resignActiveObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    /// Stops menu bar frame timers (call from `applicationWillTerminate` so timers don’t linger).
    func teardown() {
        invalidateMenubarAnimTimer()
        stopOutsideClickMonitor()
    }

    /// Call after init or when the selected Pokémon changes.
    func reloadMenubarAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.applyMenubarAnimationMode()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.imagePosition = .imageOnly
            button.action = #selector(menuBarIconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 420, height: 500)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.delegate = self

        let host = NSHostingController(
            rootView: PopoverView(
                sheet: popoverSheet,
                systemMonitor: systemMonitor,
                pokemonManager: pokemonManager,
                preferences: preferences,
                onQuit: { [weak self] in
                    self?.quitApp()
                }
            )
        )
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        popover?.contentViewController = host
    }

    private func wirePopoverContentSize() {
        popoverSizeCancellable = popoverSheet.$showPokemonPicker
            .receive(on: DispatchQueue.main)
            .sink { [weak self] expanded in
                self?.popover?.contentSize = expanded
                    ? NSSize(width: 420, height: 660)
                    : NSSize(width: 420, height: 500)
            }
    }

    func popoverDidShow(_ notification: Notification) {
        startOutsideClickMonitor()
    }

    func popoverDidClose(_ notification: Notification) {
        stopOutsideClickMonitor()
        popoverSheet.showPokemonPicker = false
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopoverIfMouseOutside()
            }
        }
        // Without Accessibility permission, global monitors are nil — `didResignActive` still helps.
    }

    private func stopOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    /// Dismiss when clicking elsewhere. Skips our status-item rect so toggle still works reliably.
    private func closePopoverIfMouseOutside() {
        guard popover?.isShown == true else { return }
        guard let popWindow = popover?.contentViewController?.view.window else { return }

        let mouse = NSEvent.mouseLocation
        if NSMouseInRect(mouse, popWindow.frame, false) { return }

        if let button = statusItem?.button, let barWindow = button.window {
            let rectInWindow = button.convert(button.bounds, to: nil)
            let screenRect = barWindow.convertToScreen(rectInWindow)
            if NSMouseInRect(mouse, screenRect, false) { return }
        }

        popover?.performClose(nil)
    }

    private func applyMenubarAnimationMode() {
        invalidateMenubarAnimTimer()
        menubarFrames = []
        menubarDelays = []
        menubarFrameIndex = 0

        let pokemon = pokemonManager.currentPokemon

        if let sheetURL = pokemonManager.urlForMenubarSleepSheet(of: pokemon),
           let decoded = SleepSheetFrameDecoder.decode(url: sheetURL),
           !decoded.frames.isEmpty {
            menubarFrames = decoded.frames
            menubarDelays = decoded.delays
            statusItem?.button?.image = menubarFramePresentation(menubarFrames[0])
            statusItem?.button?.image?.isTemplate = false
            scheduleNextMenubarFrame()
        } else {
            refreshMenubarFallbackIcon()
        }
    }

    private func scheduleNextMenubarFrame() {
        guard !menubarFrames.isEmpty else { return }

        invalidateMenubarAnimTimer()
        let idx = menubarFrameIndex % menubarFrames.count
        let delay = menubarDelays[idx % menubarDelays.count]

        menubarAnimTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.menubarFrameIndex = (self.menubarFrameIndex + 1) % self.menubarFrames.count
            let frame = self.menubarFrames[self.menubarFrameIndex]
            self.statusItem?.button?.image = self.menubarFramePresentation(frame)
            self.statusItem?.button?.image?.isTemplate = false
            self.scheduleNextMenubarFrame()
        }
        if let timer = menubarAnimTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func invalidateMenubarAnimTimer() {
        menubarAnimTimer?.invalidate()
        menubarAnimTimer = nil
    }

    /// When the sleep sheet is missing or invalid, show the first frame only or clear the icon.
    private func refreshMenubarFallbackIcon() {
        let pokemon = pokemonManager.currentPokemon
        if let sheetURL = pokemonManager.urlForMenubarSleepSheet(of: pokemon),
           let decoded = SleepSheetFrameDecoder.decode(url: sheetURL),
           let frame = decoded.frames.first {
            statusItem?.button?.image = menubarFramePresentation(frame)
            statusItem?.button?.image?.isTemplate = false
            return
        }
        statusItem?.button?.image = nil
    }

    /// Menu bar frame: nearest-neighbor pixel scaling.
    private func menubarFramePresentation(_ source: NSImage) -> NSImage {
        let w = source.size.width
        let h = source.size.height
        guard w > 0, h > 0 else { return source }

        // Scale by **height** so short-wide frames (e.g. 32×24 Charmander) match square 24×24 art.
        // Portrait frames (e.g. Pikachu 32×40) need a taller target so width matches the others visually.
        let portrait = h > w * 1.12
        let targetContentHeight: CGFloat = portrait ? 30 : 24
        let scale = min(targetContentHeight / h, 8)
        let nw = max(1, floor(w * scale))
        let nh = max(1, floor(h * scale))

        // Extra height above the sprite so vertical centering in the menu bar sits lower (like Cursor/Docker).
        let topInset: CGFloat = 4
        let canvasH = nh + topInset
        let out = NSImage(size: NSSize(width: nw, height: canvasH))
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.clear(CGRect(x: 0, y: 0, width: nw, height: canvasH))
            ctx.interpolationQuality = .none
        }
        source.draw(
            in: NSRect(x: 0, y: 0, width: nw, height: nh),
            from: NSRect(x: 0, y: 0, width: w, height: h),
            operation: .copy,
            fraction: 1.0
        )
        out.unlockFocus()
        out.isTemplate = false
        return out
    }

    @objc private func menuBarIconClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: L10n.tr("menu.about", language: preferences.appLanguage), action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.tr("menu.changePokemon", language: preferences.appLanguage), action: #selector(revealPokemonPicker), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.tr("menu.preferences", language: preferences.appLanguage), action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: L10n.tr("menu.checkUpdates", language: preferences.appLanguage), action: #selector(checkForUpdates), keyEquivalent: "u"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.tr("menu.quit", language: preferences.appLanguage), action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func showPreferences() {
        let preferencesView = SettingsView(preferences: preferences)
        let hostingController = NSHostingController(rootView: preferencesView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.tr("menu.preferences", language: preferences.appLanguage)
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 360))
        window.center()

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func checkForUpdates() {
        onCheckUpdates()
    }

    /// Opens the in-popover Pokémon strip (below stats). Shows the popover first if needed.
    @objc private func revealPokemonPicker() {
        popoverSheet.showPokemonPicker = true
        if let button = statusItem?.button, popover?.isShown == false {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
