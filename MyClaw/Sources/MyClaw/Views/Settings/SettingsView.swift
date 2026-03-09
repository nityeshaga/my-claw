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

            Section("Slack Notifications") {
                Toggle("Send Slack notifications", isOn: $settings.notifySlack)
                    .tint(Theme.success)

                if settings.notifySlack {
                    LabeledContent("Webhook URL") {
                        TextField("https://hooks.slack.com/services/...", text: $settings.slackWebhookURL)
                            .font(Theme.dataMono)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 400)
                    }

                    Button("Send Test Message") {
                        sendTestSlack()
                    }
                    .disabled(settings.slackWebhookURL.isEmpty)
                }

                Text("Sends the final response to Slack when a scheduled job finishes.")
                    .font(Theme.captionMono)
                    .foregroundStyle(Theme.textTertiary)
            }

            Section("Session Hook") {
                Toggle("Auto-install session tracking hook", isOn: $settings.hookAutoInstall)
                    .tint(Theme.success)

                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(HookInstaller.isInstalled() ? Theme.success : Theme.textTertiary)
                            .frame(width: 8, height: 8)
                        Text(HookInstaller.isInstalled() ? "Installed" : "Not installed")
                            .font(Theme.dataMono)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Text("Tracks all Claude Code sessions and logs them to the index file for monitoring.")
                    .font(Theme.captionMono)
                    .foregroundStyle(Theme.textTertiary)
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

    private func sendTestSlack() {
        let webhookURL = settings.slackWebhookURL
        guard !webhookURL.isEmpty else { return }

        let script = """
        import urllib.request, json
        payload = json.dumps({
            "text": "\\u2705 *MyClaw test* \\u2014 Slack notifications are working!"
        })
        req = urllib.request.Request(
            "\(webhookURL)",
            data=payload.encode(),
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req, timeout=10)
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script]
        try? process.run()
    }
}
