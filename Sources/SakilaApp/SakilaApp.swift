// SakilaApp.swift
// The main entry point for the Swift Blockbusters Manager application.
// Configures the app lifecycle, database service environment, and window scenes.

import SwiftUI
import AppKit

/// The root application struct that conforms to the `App` protocol.
/// Uses the `@main` attribute to designate this as the application entry point.
@main
struct SakilaApp: App {
    /// Shared database service instance injected into the SwiftUI environment
    /// so all views can access database operations.
    @State private var databaseService = DatabaseService.shared

    init() {
        // Set the activation policy to `.regular` so the app appears in the Dock
        // and receives a menu bar (required for SPM-based macOS apps).
        NSApplication.shared.setActivationPolicy(.regular)
        // Bring the app to the foreground on launch, even if other apps are active.
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        // Main application window containing the root ContentView
        WindowGroup {
            ContentView()
                // Inject the database service into the SwiftUI environment for child views
                .environment(databaseService)
        }
        // Set a comfortable default window size for the management interface
        .defaultSize(width: 1200, height: 800)

        // macOS Settings window accessible via Cmd+, from the menu bar
        Settings {
            SettingsView()
                .environment(databaseService)
        }
    }
}
