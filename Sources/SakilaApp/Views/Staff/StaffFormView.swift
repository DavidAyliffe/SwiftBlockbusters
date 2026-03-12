// StaffFormView.swift
// A modal form for adding a new staff member or editing an existing one.
// In add mode, includes an address ID field.
// In edit mode, shows personal info and active status fields.

import SwiftUI

/// Form view for creating or editing a staff member record.
/// Adapts its layout based on whether a staff member is being edited or a new one is being added.
struct StaffFormView: View {
    /// Reference to the parent view model (bindable to observe showingForm changes)
    @Bindable var viewModel: StaffViewModel
    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    // Local state properties pre-populated from the editing staff member (if any) on appear.

    /// Staff member's first name input
    @State private var firstName = ""
    /// Staff member's last name input
    @State private var lastName = ""
    /// Staff member's email address input
    @State private var email = ""
    /// Selected store ID (1 or 2)
    @State private var storeId = 1
    /// Staff member's login username input
    @State private var username = ""
    /// Whether the staff member is active/employed
    @State private var active = true
    /// Address ID for new staff (references an existing address record in the database)
    @State private var addressId = 1

    /// Convenience check: true when editing an existing staff member, false when adding new
    private var isEditing: Bool { viewModel.editingStaff != nil }

    var body: some View {
        VStack(spacing: 16) {
            // Dynamic title based on add/edit mode
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

                // Address ID field only shown when adding a new staff member
                // (requires entering an existing address_id from the database)
                if !isEditing {
                    TextField("Address ID", value: $addressId, format: .number)
                        .help("Enter an existing address ID from the database")
                }
            }
            .formStyle(.grouped)

            // Action buttons: Cancel and Save/Add
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    Task {
                        if let existing = viewModel.editingStaff {
                            // Update mode: create a modified copy and save
                            var updated = existing
                            updated.firstName = firstName
                            updated.lastName = lastName
                            updated.email = email
                            updated.storeId = storeId
                            updated.username = username
                            updated.active = active
                            await viewModel.updateStaff(updated)
                        } else {
                            // Add mode: create a new staff member
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
                // Require first name, last name, and username
                .disabled(firstName.isEmpty || lastName.isEmpty || username.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        // Adjust sheet height based on whether the address ID field is shown
        .frame(width: 400, height: isEditing ? 380 : 420)
        .onAppear {
            // Pre-populate form fields when editing an existing staff member
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
