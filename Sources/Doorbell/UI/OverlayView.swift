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
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.headline)

                HStack(spacing: 12) {
                    Button(action: onJoin) {
                        Text("Join now")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: onSnooze) {
                        Text("Snooze 5m")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .frame(maxWidth: 500)

                Button("Dismiss overlay", action: onDismiss)
                    .foregroundStyle(.white.opacity(0.9))
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
