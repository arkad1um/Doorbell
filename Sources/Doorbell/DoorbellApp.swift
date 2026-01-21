import SwiftUI
import AppKit

@main
@MainActor
struct DoorbellApp: App {
    private let container = AppContainer.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(container.appModel)
        }
        .windowStyle(.hiddenTitleBar)
        Settings {
            SettingsView()
                .environmentObject(container.appModel)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let container = AppContainer.shared
    private var statusBarController: StatusBarController?
    private var overlayController: OverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let overlayController = OverlayController(appModel: container.appModel)
        self.overlayController = overlayController
        statusBarController = StatusBarController(appModel: container.appModel)

        container.appModel.presentOverlay = { [weak overlayController] meeting in
            overlayController?.present(for: meeting)
        }
        container.appModel.dismissOverlay = { [weak overlayController] in
            overlayController?.dismiss()
        }

        container.appModel.bootstrap()
    }
}
