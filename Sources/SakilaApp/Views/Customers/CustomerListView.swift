import SwiftUI

struct CustomerListView: View {
    @State private var viewModel = CustomerViewModel()

    var body: some View {
        List {
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
        .navigationTitle("Customers (\(viewModel.customers.count))")
        .searchable(text: $viewModel.searchText, prompt: "Search customers...")
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadCustomers() }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.beginAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Customer")
            }
            ToolbarItem {
                Button {
                    Task { await viewModel.loadCustomers() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.customers.isEmpty {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showingForm) {
            CustomerFormView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadCustomers()
        }
    }
}

struct CustomerRow: View {
    let customer: Customer

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(customer.fullName)
                        .font(.headline)
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
