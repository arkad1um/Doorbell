import SwiftUI

struct StatusBarView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let next = appModel.nextMeeting {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next meeting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MeetingTile(meeting: next) {
                        appModel.join(next)
                    } showOverlay: {
                        appModel.presentOverlay?(next)
                    }
                }
            } else {
                Text("No upcoming meetings")
                    .font(.headline)
            }

            Divider()

            Text("Later today")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(appModel.meetings.dropFirst()) { meeting in
                        MeetingRow(meeting: meeting) {
                            appModel.join(meeting)
                        } showOverlay: {
                            appModel.presentOverlay?(meeting)
                        }
                    }
                }
            }
            .frame(maxHeight: 240)

            Divider()

            HStack(spacing: 8) {
                Button("Refresh") {
                    Task { await appModel.refreshMeetings() }
                }
                Button("Snooze 5") {
                    appModel.snooze(minutes: 5)
                }
                Button("Mute today") {
                    appModel.muteForRestOfDay()
                }
                Spacer()
                Menu {
                    Button("Open calendar") {
                        appModel.openCalendar()
                    }
                    Button("Quit") {
                        appModel.quitApp()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .symbolRenderingMode(.monochrome)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text(appModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 360)
    }
}
