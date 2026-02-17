import SwiftUI

struct SettingsView: View {
    @Environment(DatabaseService.self) private var db
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var db = db

        VStack(spacing: 20) {
            Text("Database Connection")
                .font(.title2.bold())

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

            if let error = db.connectionError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                if db.isConnected {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Spacer()

                    Button("Disconnect") {
                        Task { await db.disconnect() }
                    }
                    .buttonStyle(.bordered)
                } else {
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
