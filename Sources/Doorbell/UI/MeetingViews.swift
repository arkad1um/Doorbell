import SwiftUI

struct MeetingTile: View {
    let meeting: Meeting
    let joinAction: () -> Void
    let showOverlay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.headline)
                    Text("\(meeting.timeToStartDescription) • \(formatted(date: meeting.startDate))")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    if let calendarName = meeting.calendarName {
                        Text(calendarName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Button("Join") { joinAction() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button("Show overlay") { showOverlay() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            if let notes = meeting.notesSnippet {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.05)))
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct MeetingRow: View {
    let meeting: Meeting
    let joinAction: () -> Void
    let showOverlay: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(formatted(date: meeting.startDate)) • \(meeting.timeToStartDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let location = meeting.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(spacing: 6) {
                Button("Join") { joinAction() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button("Overlay") { showOverlay() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
