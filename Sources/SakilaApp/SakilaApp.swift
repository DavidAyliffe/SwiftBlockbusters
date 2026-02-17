import SwiftUI
import AppKit

@main
struct SakilaApp: App {
    @State private var databaseService = DatabaseService.shared

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(databaseService)
        }
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environment(databaseService)
        }
    }
}
