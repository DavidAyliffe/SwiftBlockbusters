// CustomerListView.swift
// Displays a searchable, scrollable list of all customers.
// Supports adding new customers, editing existing ones via context menu,
// and deleting customers. Uses CustomerFormView for add/edit operations.

import SwiftUI

/// Main customer list view with search, add, refresh, and context menu actions.
struct CustomerListView: View {
    /// ViewModel managing customer data and UI state
    @State private var viewModel = CustomerViewModel()

    var body: some View {
        List {
            // Render each customer as a row with context menu for edit/delete
            ForEach(viewModel.customers) { customer in
                CustomerRow(customer: customer)
                    .contextMenu {
                        Button("Edit") {
                            viewModel.beginEdit(customer)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteCustomer(id: customer.id) }
                        }
                    }
            }
        }
        // Navigation title shows the current count of loaded customers
        .navigationTitle("Customers (\(viewModel.customers.count))")
        // Built-in search bar for filtering customers
        .searchable(text: $viewModel.searchText, prompt: "Search customers...")
        // Reload customers whenever the search text changes
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadCustomers() }
        }
        .toolbar {
            // Add customer button
            ToolbarItem {
                Button {
                    viewModel.beginAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Customer")
            }
            // Manual refresh button
            ToolbarItem {
                Button {
                    Task { await viewModel.loadCustomers() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        // Loading spinner shown when initial load is in progress
        .overlay {
            if viewModel.isLoading && viewModel.customers.isEmpty {
                ProgressView()
            }
        }
        // Error alert dialog
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // Add/edit customer form sheet
        .sheet(isPresented: $viewModel.showingForm) {
            CustomerFormView(viewModel: viewModel)
        }
        // Load customers when the view first appears
        .task {
            await viewModel.loadCustomers()
        }
    }
}

/// A row component displaying a single customer's information.
/// Shows the customer's name, active status badge, email, store, and city.
struct CustomerRow: View {
    /// The customer data to display
    let customer: Customer

    var body: some View {
        HStack {
            // Left side: name, status badge, and email
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(customer.fullName)
                        .font(.headline)
                    // Show an "Inactive" badge if the customer is deactivated
                    if !customer.active {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                if let email = customer.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right side: store number and city
            VStack(alignment: .trailing, spacing: 2) {
                Text("Store \(customer.storeId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let city = customer.city {
                    Text(city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
