import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var leadMinutes: Int = 10
    @State private var launchAtLogin: Bool = false
    private let options: [Int] = [1, 5, 10, 15, 30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reminder lead time")
                    .font(.headline)
                Picker("Lead time", selection: $leadMinutes) {
                    ForEach(options, id: \.self) { value in
                        Text("\(value) мин").tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text("Показывать оверлей за \(leadMinutes) мин до начала")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Quiet hours")
                    .font(.headline)
                Button("Mute until tomorrow") {
                    appModel.muteForRestOfDay()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Launch")
                    .font(.headline)
                Toggle("Запускать при входе в систему", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, newValue in
                        appModel.toggleLaunchAtLogin(newValue)
                    }
                    .help("Запускать приложение автоматически после старта macOS")
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 260)
        .onAppear {
            let current = Int(appModel.leadTime / 60)
            leadMinutes = options.min(by: { abs($0 - current) < abs($1 - current) }) ?? 10
            launchAtLogin = appModel.launchAtLogin
        }
        .onChange(of: leadMinutes) { oldValue, newValue in
            if oldValue != newValue {
                appModel.updateLeadTime(minutes: Double(newValue))
            }
        }
    }
}
