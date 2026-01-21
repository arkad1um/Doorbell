import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doorbell")
                .font(.title)
                .fontWeight(.semibold)

            if let next = appModel.nextMeeting {
                MeetingTile(meeting: next) {
                    appModel.join(next)
                } showOverlay: {
                    appModel.presentOverlay?(next)
                }
            } else {
                Text("No upcoming meetings")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Upcoming")
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(appModel.meetings) { meeting in
                        MeetingRow(meeting: meeting) {
                            appModel.join(meeting)
                        } showOverlay: {
                            appModel.presentOverlay?(meeting)
                        }
                    }
                }
            }

            HStack {
                Button("Refresh") {
                    Task { await appModel.refreshMeetings() }
                }
                Button("Open Calendar") {
                    appModel.openCalendar()
                }
                Spacer()
                Text(appModel.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 360)
    }
}
