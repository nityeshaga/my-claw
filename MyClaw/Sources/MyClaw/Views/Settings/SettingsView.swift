import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared

    var body: some View {
        Form {
            Section("Paths") {
                LabeledContent("Claude Binary") {
                    TextField("", text: $settings.claudeBinaryPath)
                        .font(Theme.dataMono)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
                LabeledContent("Index File") {
                    TextField("", text: $settings.indexFilePath)
                        .font(Theme.dataMono)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
                LabeledContent("Scripts Directory") {
                    TextField("", text: $settings.scriptsDirectory)
                        .font(Theme.dataMono)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                }
            }

            Section("Notifications") {
                Toggle("Show notifications", isOn: $settings.showNotifications)
                    .tint(Theme.success)
                Toggle("Only on failure", isOn: $settings.notifyOnFailureOnly)
                    .tint(Theme.success)
                    .disabled(!settings.showNotifications)
            }

            Section("Updates") {
                LabeledContent("Current Version") {
                    Text(UpdateChecker.currentVersion)
                        .font(Theme.dataMono)
                        .foregroundStyle(Theme.textSecondary)
                }

                if updateChecker.updateAvailable, let latest = updateChecker.latestVersion {
                    LabeledContent("Latest Version") {
                        HStack(spacing: 8) {
                            Text(latest)
                                .font(Theme.dataMono)
                                .foregroundStyle(Theme.success)
                            ArcadeBadge(text: "NEW", color: Theme.success)
                        }
                    }

                    if let notes = updateChecker.releaseNotes, !notes.isEmpty {
                        LabeledContent("Release Notes") {
                            Text(notes)
                                .font(Theme.captionMono)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(4)
                                .frame(maxWidth: 400, alignment: .leading)
                        }
                    }

                    if let url = updateChecker.downloadURL {
                        Button("Download Update") {
                            if let downloadURL = URL(string: url) {
                                NSWorkspace.shared.open(downloadURL)
                            }
                        }
                        .tint(Theme.coral)
                    }
                } else if !updateChecker.checking {
                    LabeledContent("Status") {
                        Text("Up to date")
                            .font(Theme.dataMono)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Button {
                    updateChecker.check()
                } label: {
                    HStack(spacing: 6) {
                        if updateChecker.checking {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(updateChecker.checking ? "Checking..." : "Check for Updates")
                    }
                }
                .disabled(updateChecker.checking)
            }

            Section("Info") {
                LabeledContent("LaunchAgents") {
                    Text(settings.launchAgentsDirectory)
                        .font(Theme.dataMono)
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
