import SwiftUI

struct StaffFormView: View {
    @Bindable var viewModel: StaffViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var storeId = 1
    @State private var username = ""
    @State private var active = true
    @State private var addressId = 1

    private var isEditing: Bool { viewModel.editingStaff != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Staff" : "Add Staff")
                .font(.title2.bold())

            Form {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Email", text: $email)
                TextField("Username", text: $username)
                Picker("Store", selection: $storeId) {
                    Text("Store 1").tag(1)
                    Text("Store 2").tag(2)
                }
                Toggle("Active", isOn: $active)

                if !isEditing {
                    TextField("Address ID", value: $addressId, format: .number)
                        .help("Enter an existing address ID from the database")
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    Task {
                        if let existing = viewModel.editingStaff {
                            var updated = existing
                            updated.firstName = firstName
                            updated.lastName = lastName
                            updated.email = email
                            updated.storeId = storeId
                            updated.username = username
                            updated.active = active
                            await viewModel.updateStaff(updated)
                        } else {
                            await viewModel.addStaff(
                                firstName: firstName, lastName: lastName,
                                email: email, storeId: storeId,
                                username: username, addressId: addressId
                            )
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(firstName.isEmpty || lastName.isEmpty || username.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: isEditing ? 380 : 420)
        .onAppear {
            if let staff = viewModel.editingStaff {
                firstName = staff.firstName
                lastName = staff.lastName
                email = staff.email ?? ""
                storeId = staff.storeId
                username = staff.username
                active = staff.active
            }
        }
    }
}
