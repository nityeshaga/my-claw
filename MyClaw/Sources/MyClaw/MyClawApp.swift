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
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    dataStore.load()
                    NotificationService.setup()
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
            List(selection: $selection) {
                Section("Overview") {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                        .tag(SidebarItem.dashboard)
                }
                Section("Manage") {
                    Label("Scheduled Jobs", systemImage: "clock.badge.checkmark")
                        .tag(SidebarItem.jobs)
                    Label("Sessions", systemImage: "text.bubble")
                        .tag(SidebarItem.sessions)
                }
                Section {
                    Label("Settings", systemImage: "gear")
                        .tag(SidebarItem.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("My Claw")
            .safeAreaInset(edge: .bottom) {
                Button {
                    showJobEditor = true
                } label: {
                    Label("New Claude", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
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
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Sessions")
                        .font(.headline)
                    Text("Sessions will appear here after Claude runs complete.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    SessionListView(sessions: filteredSessions)
                        .padding()
                }
            }
        }
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
                .font(.headline)

            Divider()

            // Quick stats
            HStack {
                Label("\(dataStore.jobs.count) jobs", systemImage: "clock")
                Spacer()
                Label("\(dataStore.sessionsToday.count) today", systemImage: "text.bubble")
            }
            .font(.caption)

            Divider()

            // Recent sessions
            Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(dataStore.sessions.prefix(3))) { session in
                HStack {
                    Circle()
                        .fill(StatusColor.forReason(session.reason))
                        .frame(width: 6, height: 6)
                    Text(session.projectName)
                        .lineLimit(1)
                    Spacer()
                    if let date = session.finishedDate {
                        Text(DateFormatting.relativeString(from: date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
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
