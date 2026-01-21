import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

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
