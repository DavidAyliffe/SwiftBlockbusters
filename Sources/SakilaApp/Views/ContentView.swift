// ContentView.swift
// The root view of the application, providing the main navigation structure.
// Uses a NavigationSplitView with a sidebar for section navigation
// and a detail area that displays the selected section's content.

import SwiftUI

/// Enum defining all available sidebar navigation items.
/// Each case maps to a top-level section of the application.
enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case films = "Films"
    case customers = "Customers"
    case staff = "Staff"
    case rentals = "Rentals"

    /// Uses the raw string value as the unique identifier for SwiftUI lists
    var id: String { rawValue }

    /// SF Symbol icon name for each sidebar item
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

/// The main content view that provides the app's navigation structure.
/// Displays a sidebar with section links and a detail area with the selected section's content.
/// Shows a connection prompt when the database is not connected.
struct ContentView: View {
    /// Database service injected from the SwiftUI environment
    @Environment(DatabaseService.self) private var db
    /// The currently selected sidebar item (defaults to Dashboard)
    @State private var selectedItem: SidebarItem? = .dashboard
    /// Controls the visibility of the settings/connection sheet
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            // Sidebar: list of navigable sections
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Sakila Manager")
            .toolbar {
                // Connection status indicator — shows green bolt when connected, red when not
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
            // Detail area: show the selected section's view when connected
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
                // Disconnected state: prompt the user to configure the database connection
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
        // Settings sheet for database connection configuration
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(db)
        }
    }
}
