import SwiftUI

@main
struct MyClawApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    dataStore.load()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 750)
    }
}

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DashboardView()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selection: SidebarItem? = .dashboard

    enum SidebarItem: Hashable {
        case dashboard
        case jobs
        case sessions
        case settings
    }

    var body: some View {
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
    }
}
