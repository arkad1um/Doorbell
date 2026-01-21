import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    private let appModel: AppModel
    private var window: NSWindow?

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    func present(for meeting: Meeting) {
        dismiss()

        let hostingController = NSHostingController(
            rootView: OverlayView(
                meeting: meeting,
                onJoin: { [weak self] in self?.appModel.join(meeting) },
                onSnooze: { [weak self] in self?.appModel.snooze(minutes: 5) },
                onDismiss: { [weak self] in self?.dismiss() }
            )
        )

        let overlayWindow = NSWindow(contentViewController: hostingController)
        overlayWindow.styleMask = [.borderless]
        overlayWindow.level = .screenSaver
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        overlayWindow.titleVisibility = .hidden

        if let screen = NSScreen.main {
            overlayWindow.setFrame(screen.frame, display: true)
        }

        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()
        window = overlayWindow
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
    }
}
