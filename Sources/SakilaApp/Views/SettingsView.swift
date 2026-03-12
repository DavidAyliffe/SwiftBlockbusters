// SettingsView.swift
// Database connection configuration view.
// Allows the user to enter MySQL connection parameters (host, port, username, password, database)
// and connect/disconnect from the database. Displayed as a sheet or in the Settings window.

import SwiftUI

/// Settings view for configuring the MySQL database connection.
/// Provides text fields for connection parameters and connect/disconnect controls.
struct SettingsView: View {
    /// Database service injected from the SwiftUI environment
    @Environment(DatabaseService.self) private var db
    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Create a bindable wrapper to enable two-way binding on @Observable properties
        @Bindable var db = db

        VStack(spacing: 20) {
            Text("Database Connection")
                .font(.title2.bold())

            // Connection parameter form fields
            Form {
                TextField("Host", text: $db.host)
                    .textFieldStyle(.roundedBorder)
                TextField("Port", value: $db.port, format: .number)
                    .textFieldStyle(.roundedBorder)
                TextField("Username", text: $db.username)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $db.password)
                    .textFieldStyle(.roundedBorder)
                TextField("Database", text: $db.database)
                    .textFieldStyle(.roundedBorder)
            }
            .formStyle(.grouped)

            // Display connection error message if the last attempt failed
            if let error = db.connectionError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // Connection status indicator and action button
            HStack {
                if db.isConnected {
                    // Connected state: show green checkmark and disconnect button
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Spacer()

                    Button("Disconnect") {
                        Task { await db.disconnect() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    // Disconnected state: show red X and connect button
                    Label("Disconnected", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)

                    Spacer()

                    Button("Connect") {
                        Task { await db.connect() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()

            // Close button aligned to the right, bound to Escape key
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(width: 400, height: 420)
    }
}
