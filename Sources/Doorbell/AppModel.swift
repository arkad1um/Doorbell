import Foundation
import Combine
import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var meetings: [Meeting] = []
    @Published private(set) var nextMeeting: Meeting?
    @Published var leadTime: TimeInterval = 180
    @Published var statusMessage: String = "Waiting for calendar access"
    @Published var mutedUntil: Date?
    @Published var launchAtLogin: Bool = false
    @Published private(set) var isMuted: Bool = false

    var presentOverlay: ((Meeting) -> Void)?
    var dismissOverlay: (() -> Void)?
    private var settingsWindow: NSWindow?

    private let calendarService: CalendarService
    private let scheduler: Scheduler
    private var cancellables: Set<AnyCancellable> = []
    private var bootstrapped = false

    init(calendarService: CalendarService, scheduler: Scheduler) {
        self.calendarService = calendarService
        self.scheduler = scheduler
        scheduler.delegate = self
    }

    func bootstrap() {
        guard !bootstrapped else { return }
        bootstrapped = true
        Task {
            await refreshMeetings()
        }
    }

    func refreshMeetings() async {
        do {
            try await calendarService.ensureAccess()
            let fetched = try await calendarService.upcomingMeetings(limit: 8)
            statusMessage = fetched.isEmpty ? "No meetings planned" : "Up to date"
            apply(meetings: fetched)
        } catch {
            let fallback = CalendarService.sampleMeetings()
            statusMessage = "Showing sample data (calendar access missing)"
            apply(meetings: fallback)
        }
    }

    func join(_ meeting: Meeting) {
        guard let url = meeting.joinURL else { return }
        NSWorkspace.shared.open(url)
        dismissOverlay?()
    }

    func openCalendar() {
        let calendarURL = URL(fileURLWithPath: "/System/Applications/Calendar.app")
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: calendarURL, configuration: configuration, completionHandler: nil)
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        // TODO: hook into SMAppService or LaunchAgent here when packaging as bundle.
    }

    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: SettingsView().environmentObject(self))
        let window = NSWindow(contentViewController: controller)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setFrameAutosaveName("DoorbellSettings")
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    func snooze(minutes: Int = 5) {
        scheduler.snooze(minutes: minutes)
        statusMessage = "Snoozed for \(minutes) min"
        dismissOverlay?()
    }

    func muteForRestOfDay() {
        let now = Date()
        if isMuted {
            unmute()
        } else {
            mutedUntil = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
            dismissOverlay?()
            isMuted = true
        }
    }

    func unmute() {
        mutedUntil = nil
        isMuted = false
    }

    func updateLeadTime(minutes: Double) {
        leadTime = max(60, minutes * 60)
        scheduler.schedule(meeting: nextMeeting, leadTime: leadTime)
    }

    func refreshMuteState() {
        if let mutedUntil {
            isMuted = Date() < mutedUntil
        } else {
            isMuted = false
        }
    }

    private func apply(meetings: [Meeting]) {
        self.meetings = meetings
        nextMeeting = meetings.first
        scheduler.schedule(meeting: nextMeeting, leadTime: leadTime)
    }
}

extension AppModel: SchedulerDelegate {
    func scheduler(_ scheduler: Scheduler, didTrigger meeting: Meeting) {
        refreshMuteState()
        guard !isMuted else { return }
        presentOverlay?(meeting)
    }
}
