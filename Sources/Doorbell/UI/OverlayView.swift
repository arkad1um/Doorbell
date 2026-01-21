import SwiftUI

struct OverlayView: View {
    let meeting: Meeting
    let onJoin: () -> Void
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Upcoming call")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))

                Text(meeting.title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Starts \(meeting.timeToStartDescription) at \(formatted(date: meeting.startDate))")
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.headline)

                HStack(spacing: 12) {
                    Button("Join now", action: onJoin)
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.9))
                        .foregroundStyle(.white)
                        .controlSize(.large)

                    Button("Snooze 5m", action: onSnooze)
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.9))
                        .foregroundStyle(.white)
                        .controlSize(.large)
                }
                .frame(maxWidth: 520)

                Button("Dismiss overlay", action: onDismiss)
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
                    .foregroundStyle(.white)
            }
            .padding(40)
        }
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
