import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    init(appModel: AppModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusBarView(appModel: appModel))

        if let button = statusItem.button {
            let image = makeStatusImage()
            button.image = image
            button.imagePosition = .imageOnly
            button.title = image == nil ? "Doorbell" : ""
            button.target = self
            button.action = #selector(togglePopover)
        }

        startMonitoringClicks()
    }

    deinit {
        scheduleStopMonitoring()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.becomeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func startMonitoringClicks() {
        // Close popover when clicking anywhere outside it (menu-bar style).
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleClick(event)
        }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleClick(event)
            return event
        }
    }

    private func stopMonitoringClicks() {
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
    }

    nonisolated private func scheduleStopMonitoring() {
        Task { @MainActor [weak self] in
            self?.stopMonitoringClicks()
        }
    }

    private func handleClick(_ event: NSEvent) {
        guard popover.isShown else { return }
        if let window = popover.contentViewController?.view.window, event.window == window {
            return
        }
        closePopover()
    }

    private func makeStatusImage() -> NSImage? {
        let primary = "bell.and.waves.left.and.right.fill"
        let fallback = "bell.fill"
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)

        let image = NSImage(
            systemSymbolName: primary,
            accessibilityDescription: "Doorbell"
        )?.withSymbolConfiguration(config) ?? NSImage(
            systemSymbolName: fallback,
            accessibilityDescription: "Doorbell"
        )?.withSymbolConfiguration(config)

        image?.isTemplate = true
        return image
    }
}
