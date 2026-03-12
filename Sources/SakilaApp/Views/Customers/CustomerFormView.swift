// CustomerFormView.swift
// A modal form for adding a new customer or editing an existing one.
// In add mode, includes address fields and a city picker.
// In edit mode, shows only the personal info fields (name, email, store, active status).

import SwiftUI

/// Form view for creating or editing a customer record.
/// Adapts its layout based on whether a customer is being edited or a new one is being added.
struct CustomerFormView: View {
    /// Reference to the parent view model (bindable to observe showingForm changes)
    @Bindable var viewModel: CustomerViewModel
    /// Dismiss action for closing the sheet
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    // Local state properties pre-populated from the editing customer (if any) on appear.

    /// Customer's first name input
    @State private var firstName = ""
    /// Customer's last name input
    @State private var lastName = ""
    /// Customer's email address input
    @State private var email = ""
    /// Selected store ID (1 or 2)
    @State private var storeId = 1
    /// Whether the customer account is active (edit mode only)
    @State private var active = true
    /// Street address input (add mode only)
    @State private var address = ""
    /// District/region input (add mode only)
    @State private var district = ""
    /// Selected city ID from the city picker (add mode only)
    @State private var cityId = 1
    /// Postal/ZIP code input (add mode only)
    @State private var postalCode = ""
    /// Phone number input (add mode only)
    @State private var phone = ""

    /// Convenience check: true when editing an existing customer, false when adding new
    private var isEditing: Bool { viewModel.editingCustomer != nil }

    var body: some View {
        VStack(spacing: 16) {
            // Dynamic title based on add/edit mode
            Text(isEditing ? "Edit Customer" : "Add Customer")
                .font(.title2.bold())

            Form {
                // Personal information section (always shown)
                Section("Personal Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    Picker("Store", selection: $storeId) {
                        Text("Store 1").tag(1)
                        Text("Store 2").tag(2)
                    }
                    // Active toggle only shown when editing (new customers default to active)
                    if isEditing {
                        Toggle("Active", isOn: $active)
                    }
                }

                // Address section only shown when adding a new customer
                // (editing a customer's address is not supported in this form)
                if !isEditing {
                    Section("Address") {
                        TextField("Address", text: $address)
                        TextField("District", text: $district)
                        // City picker populated from the database
                        Picker("City", selection: $cityId) {
                            ForEach(viewModel.cities, id: \.id) { city in
                                Text(city.name).tag(city.id)
                            }
                        }
                        TextField("Postal Code", text: $postalCode)
                        TextField("Phone", text: $phone)
                    }
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
                        if let existing = viewModel.editingCustomer {
                            // Update mode: create a modified copy and save
                            var updated = existing
                            updated.firstName = firstName
                            updated.lastName = lastName
                            updated.email = email
                            updated.storeId = storeId
                            updated.active = active
                            await viewModel.updateCustomer(updated)
                        } else {
                            // Add mode: create a new customer with address
                            await viewModel.addCustomer(
                                firstName: firstName, lastName: lastName, email: email,
                                storeId: storeId, address: address, district: district,
                                cityId: cityId, postalCode: postalCode, phone: phone
                            )
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                // Require at minimum a first and last name
                .disabled(firstName.isEmpty || lastName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        // Adjust sheet height based on whether address fields are shown
        .frame(width: 450, height: isEditing ? 350 : 520)
        .onAppear {
            // Pre-populate form fields when editing an existing customer
            if let customer = viewModel.editingCustomer {
                firstName = customer.firstName
                lastName = customer.lastName
                email = customer.email ?? ""
                storeId = customer.storeId
                active = customer.active
            }
        }
        .task {
            // Load cities for the address picker when adding a new customer
            if !isEditing {
                await viewModel.loadCities()
            }
        }
    }
}
