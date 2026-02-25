import SwiftUI
import AppKit

@main
struct MyClawApp: App {
    @StateObject private var dataStore = DataStore()
    @State private var showNewSession = false

    var body: some Scene {
        WindowGroup {
            ContentView(showNewSession: $showNewSession)
                .environmentObject(dataStore)
                .preferredColorScheme(.dark)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    dataStore.load()
                    NotificationService.setup()
                    UpdateChecker.shared.checkIfNeeded()
                }
                .sheet(isPresented: $showNewSession) {
                    NewSessionView()
                        .environmentObject(dataStore)
                        .frame(minWidth: 600, minHeight: 450)
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Session") {
                    showNewSession = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    UpdateChecker.shared.check()
                }
            }
        }

        MenuBarExtra {
            MenuBarView(showNewSession: $showNewSession)
                .environmentObject(dataStore)
        } label: {
            Image(systemName: menuBarIcon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(menuBarTint, .primary)
        }
    }

    private var menuBarIcon: String { "terminal.fill" }

    private var menuBarTint: Color {
        StatusColor.menuBarTint(jobs: dataStore.jobs, recentSessions: dataStore.sessions)
    }
}

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var showNewSession: Bool
    @State private var selection: SidebarItem? = .dashboard
    @State private var showJobEditor = false

    enum SidebarItem: Hashable {
        case dashboard
        case jobs
        case sessions
        case settings
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                // Logo / title area
                HStack(spacing: 8) {
                    Image(systemName: "arcade.stick")
                        .font(.title2)
                        .foregroundStyle(Theme.coral)
                        .shadow(color: Theme.coral.opacity(0.5), radius: 6)
                    Text("MY CLAW")
                        .font(Theme.titleMono)
                        .foregroundStyle(Theme.cream)
                        .tracking(3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Section: Overview
                SidebarSection(title: "OVERVIEW")
                SidebarRow(
                    label: "Dashboard",
                    icon: "square.grid.2x2",
                    color: Theme.neonCyan,
                    isSelected: selection == .dashboard
                ) { selection = .dashboard }

                // Section: Manage
                SidebarSection(title: "MANAGE")
                SidebarRow(
                    label: "Scheduled Jobs",
                    icon: "clock.badge.checkmark",
                    color: Theme.neonAmber,
                    isSelected: selection == .jobs
                ) { selection = .jobs }
                SidebarRow(
                    label: "Sessions",
                    icon: "text.bubble",
                    color: Theme.neonPurple,
                    isSelected: selection == .sessions
                ) { selection = .sessions }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                SidebarRow(
                    label: "Settings",
                    icon: "gear",
                    color: Theme.textSecondary,
                    isSelected: selection == .settings
                ) { selection = .settings }

                Spacer()

                // New Claude button with glow
                Button {
                    showJobEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("NEW CLAUDE")
                            .font(Theme.headingMono)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.coral, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .shadow(color: Theme.coral.opacity(0.5), radius: 12)
                .shadow(color: Theme.coral.opacity(0.2), radius: 20)
                .padding(16)
            }
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
            .background(Theme.bgDeep)
            .sheet(isPresented: $showJobEditor) {
                JobEditorSheet { dataStore.refresh() }
                    .frame(minWidth: 500, minHeight: 400)
            }
        } detail: {
            Group {
                switch selection {
                case .dashboard, .none:
                    DashboardView()
                case .jobs:
                    JobManagerView()
                case .sessions:
                    AllSessionsView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

/// Full sessions list with search
struct AllSessionsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""

    var filteredSessions: [SessionRun] {
        if searchText.isEmpty { return dataStore.sessions }
        let query = searchText.lowercased()
        return dataStore.sessions.filter {
            $0.sessionId.lowercased().contains(query) ||
            $0.cwd.lowercased().contains(query) ||
            $0.projectName.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if dataStore.sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(Theme.displayMono)
                        .foregroundStyle(Theme.textTertiary)
                    Text("No Sessions")
                        .font(Theme.headingMono)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Sessions will appear here after Claude runs complete.")
                        .font(Theme.bodyText)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    SessionListView(sessions: filteredSessions)
                        .padding()
                }
            }
        }
        .background(Theme.bgDeep)
        .navigationTitle("Sessions (\(dataStore.sessions.count))")
        .searchable(text: $searchText, prompt: "Search sessions...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dataStore.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
    }
}

/// Menu bar dropdown
struct MenuBarView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var showNewSession: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My Claw")
                .font(Theme.headingMono)
                .foregroundStyle(Theme.textPrimary)

            Divider()

            // Quick stats
            HStack {
                Label("\(dataStore.jobs.count) jobs", systemImage: "clock")
                    .foregroundStyle(Theme.neonCyan)
                Spacer()
                Label("\(dataStore.sessionsToday.count) today", systemImage: "text.bubble")
                    .foregroundStyle(Theme.success)
            }
            .font(Theme.captionMono)

            Divider()

            // Recent sessions
            Text("Recent")
                .font(Theme.captionMono)
                .foregroundStyle(Theme.textTertiary)

            ForEach(Array(dataStore.sessions.prefix(3))) { session in
                HStack {
                    StatusDot(
                        color: StatusColor.forReason(session.reason),
                        size: 6
                    )
                    Text(session.projectName)
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let date = session.finishedDate {
                        Text(DateFormatting.relativeString(from: date))
                            .font(Theme.codeMono)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Divider()

            Button("New Session...") {
                showNewSession = true
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Open Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 240)
    }
}

// MARK: - Custom Sidebar Components

struct SidebarSection: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.codeMono)
            .foregroundStyle(Theme.textTertiary)
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}

struct SidebarRow: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? color : Theme.textSecondary)
                    .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 4)
                    .frame(width: 22)
                Text(label)
                    .font(Theme.dataMono)
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
                if isSelected {
                    Rectangle()
                        .fill(color)
                        .frame(width: 3, height: 18)
                        .cornerRadius(2)
                        .shadow(color: color.opacity(0.6), radius: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                        ? color.opacity(0.12)
                        : (isHovered ? Color.white.opacity(0.04) : Color.clear)
                )
                .padding(.horizontal, 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
                .padding(.horizontal, 8)
        )
        .onHover { isHovered = $0 }
    }
}
