import Foundation
import Combine
import AppKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var meetings: [Meeting] = []
    @Published private(set) var nextMeeting: Meeting?
    @Published var leadTime: TimeInterval = 180
    @Published var statusMessage: String = "Waiting for calendar access"
    @Published var mutedUntil: Date?

    var presentOverlay: ((Meeting) -> Void)?
    var dismissOverlay: (() -> Void)?

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

    func quitApp() {
        NSApp.terminate(nil)
    }

    func snooze(minutes: Int = 5) {
        scheduler.snooze(minutes: minutes)
    }

    func muteForRestOfDay() {
        mutedUntil = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        dismissOverlay?()
    }

    func updateLeadTime(minutes: Double) {
        leadTime = max(60, minutes * 60)
        scheduler.schedule(meeting: nextMeeting, leadTime: leadTime)
    }

    private func apply(meetings: [Meeting]) {
        self.meetings = meetings
        nextMeeting = meetings.first
        scheduler.schedule(meeting: nextMeeting, leadTime: leadTime)
    }
}

extension AppModel: SchedulerDelegate {
    func scheduler(_ scheduler: Scheduler, didTrigger meeting: Meeting) {
        guard !isMuted else { return }
        presentOverlay?(meeting)
    }

    private var isMuted: Bool {
        guard let mutedUntil else { return false }
        return Date() < mutedUntil
    }
}
