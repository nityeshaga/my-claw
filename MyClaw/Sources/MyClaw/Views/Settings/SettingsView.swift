import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Paths") {
                LabeledContent("Claude Binary") {
                    TextField("", text: $settings.claudeBinaryPath)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
                LabeledContent("Index File") {
                    TextField("", text: $settings.indexFilePath)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
                LabeledContent("Scripts Directory") {
                    TextField("", text: $settings.scriptsDirectory)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
            }

            Section("Notifications") {
                Toggle("Show notifications", isOn: $settings.showNotifications)
                Toggle("Only on failure", isOn: $settings.notifyOnFailureOnly)
                    .disabled(!settings.showNotifications)
            }

            Section("Info") {
                LabeledContent("LaunchAgents") {
                    Text(settings.launchAgentsDirectory)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
