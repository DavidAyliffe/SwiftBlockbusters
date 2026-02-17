import SwiftUI

struct CustomerFormView: View {
    @Bindable var viewModel: CustomerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var storeId = 1
    @State private var active = true
    @State private var address = ""
    @State private var district = ""
    @State private var cityId = 1
    @State private var postalCode = ""
    @State private var phone = ""

    private var isEditing: Bool { viewModel.editingCustomer != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Customer" : "Add Customer")
                .font(.title2.bold())

            Form {
                Section("Personal Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    Picker("Store", selection: $storeId) {
                        Text("Store 1").tag(1)
                        Text("Store 2").tag(2)
                    }
                    if isEditing {
                        Toggle("Active", isOn: $active)
                    }
                }

                if !isEditing {
                    Section("Address") {
                        TextField("Address", text: $address)
                        TextField("District", text: $district)
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

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    Task {
                        if let existing = viewModel.editingCustomer {
                            var updated = existing
                            updated.firstName = firstName
                            updated.lastName = lastName
                            updated.email = email
                            updated.storeId = storeId
                            updated.active = active
                            await viewModel.updateCustomer(updated)
                        } else {
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
                .disabled(firstName.isEmpty || lastName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 450, height: isEditing ? 350 : 520)
        .onAppear {
            if let customer = viewModel.editingCustomer {
                firstName = customer.firstName
                lastName = customer.lastName
                email = customer.email ?? ""
                storeId = customer.storeId
                active = customer.active
            }
        }
        .task {
            if !isEditing {
                await viewModel.loadCities()
            }
        }
    }
}
