import Foundation
import EventKit

enum CalendarServiceError: Error {
    case accessDenied
    case accessRestricted
}

@MainActor
final class CalendarService {
    private let eventStore = EKEventStore()
    private let linkExtractor: MeetingLinkExtractor

    init(linkExtractor: MeetingLinkExtractor) {
        self.linkExtractor = linkExtractor
    }

    func ensureAccess() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .writeOnly, .fullAccess:
            return
        case .notDetermined:
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else { throw CalendarServiceError.accessDenied }
        case .denied:
            throw CalendarServiceError.accessDenied
        case .restricted:
            throw CalendarServiceError.accessRestricted
        @unknown default:
            throw CalendarServiceError.accessDenied
        }
    }

    func upcomingMeetings(limit: Int = 5, windowHours: Double = 8) async throws -> [Meeting] {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(windowHours * 3600)

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { $0.startDate >= startDate }
            .sorted { $0.startDate < $1.startDate }

        let meetings = events.prefix(limit).map { event in
            let link = linkExtractor.extract(from: event)
            return Meeting(event: event, joinURL: link)
        }
        return meetings
    }

    static func sampleMeetings(now: Date = Date()) -> [Meeting] {
        let calendar = Calendar.current
        let inThirty = calendar.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(30 * 60)
        let inNinety = calendar.date(byAdding: .minute, value: 90, to: now) ?? now.addingTimeInterval(90 * 60)

        let first = Meeting(
            id: UUID().uuidString,
            title: "Daily sync",
            startDate: inThirty,
            endDate: calendar.date(byAdding: .minute, value: 25, to: inThirty) ?? inThirty.addingTimeInterval(25 * 60),
            location: "Meet",
            joinURL: URL(string: "https://meet.google.com/door-bell-sync"),
            calendarName: "Work",
            notesSnippet: "Triage and blockers."
        )

        let second = Meeting(
            id: UUID().uuidString,
            title: "Product review",
            startDate: inNinety,
            endDate: calendar.date(byAdding: .minute, value: 50, to: inNinety) ?? inNinety.addingTimeInterval(50 * 60),
            location: "Zoom",
            joinURL: URL(string: "https://zoom.us/j/123456789"),
            calendarName: "Work",
            notesSnippet: "Walk through new flows."
        )

        return [first, second]
    }
}
