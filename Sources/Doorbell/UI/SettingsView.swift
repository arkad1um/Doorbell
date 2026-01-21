import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var leadMinutes: Double = 3

    var body: some View {
        Form {
            Section("Reminder lead time") {
                Slider(value: $leadMinutes, in: 1...10, step: 1) {
                    Text("Lead time (minutes)")
                }
                HStack {
                    Text("Show overlay \(Int(leadMinutes)) minutes before start")
                    Spacer()
                    Button("Apply") {
                        appModel.updateLeadTime(minutes: leadMinutes)
                    }
                }
            }

            Section("Quiet hours") {
                Button("Mute until tomorrow") {
                    appModel.muteForRestOfDay()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 200)
        .onAppear {
            leadMinutes = max(1, appModel.leadTime / 60)
        }
    }
}
