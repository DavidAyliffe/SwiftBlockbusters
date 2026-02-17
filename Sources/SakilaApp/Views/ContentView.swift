import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case films = "Films"
    case customers = "Customers"
    case staff = "Staff"
    case rentals = "Rentals"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .films: return "film"
        case .customers: return "person.2.fill"
        case .staff: return "person.badge.key.fill"
        case .rentals: return "arrow.triangle.2.circlepath"
        }
    }
}

struct ContentView: View {
    @Environment(DatabaseService.self) private var db
    @State private var selectedItem: SidebarItem? = .dashboard
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Sakila Manager")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: db.isConnected ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundStyle(db.isConnected ? .green : .red)
                    }
                    .help(db.isConnected ? "Connected" : "Disconnected — Click to configure")
                }
            }
        } detail: {
            if db.isConnected {
                switch selectedItem {
                case .dashboard:
                    DashboardView()
                case .films:
                    FilmListView()
                case .customers:
                    CustomerListView()
                case .staff:
                    StaffListView()
                case .rentals:
                    RentalView()
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Not Connected")
                        .font(.title2)
                    Text("Configure your database connection to get started.")
                        .foregroundStyle(.secondary)
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(db)
        }
    }
}
