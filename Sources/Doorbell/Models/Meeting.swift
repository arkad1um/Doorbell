import Foundation
import EventKit

struct Meeting: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let joinURL: URL?
    let calendarName: String?
    let notesSnippet: String?

    var isOngoing: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var timeToStartDescription: String {
        let now = Date()
        let delta = startDate.timeIntervalSince(now)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(fromTimeInterval: delta)
    }
}

extension Meeting {
    init(event: EKEvent, joinURL: URL?) {
        id = event.eventIdentifier ?? UUID().uuidString
        title = event.title
        startDate = event.startDate
        endDate = event.endDate
        location = event.location
        calendarName = event.calendar.title
        notesSnippet = Meeting.trimmedNotes(event.notes)
        self.joinURL = joinURL
    }

    private static func trimmedNotes(_ notes: String?) -> String? {
        guard let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmed = notes.replacingOccurrences(of: "\n", with: " ")
        if trimmed.count > 160 {
            let prefix = trimmed.prefix(157)
            return prefix + "..."
        }
        return trimmed
    }
}
