import SwiftUI

struct RentalView: View {
    @State private var viewModel = RentalViewModel()

    var body: some View {
        HSplitView {
            // Active rentals list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Active Rentals")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.activeRentals.count)")
                        .foregroundStyle(.secondary)
                }
                .padding()

                List(viewModel.activeRentals) { rental in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rental.filmTitle ?? "Unknown Film")
                                .font(.headline)
                            Text(rental.customerName ?? "Unknown Customer")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("Rented: \(rental.rentalDate, style: .date)")
                                    .font(.caption)
                                Text("by \(rental.staffName ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button("Return") {
                            Task { await viewModel.processReturn(rentalId: rental.id) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(minWidth: 400)

            // New rental panel
            VStack(alignment: .leading, spacing: 16) {
                Text("New Rental")
                    .font(.headline)
                    .padding(.horizontal)

                Form {
                    // Step 1: Select customer
                    Section("1. Select Customer") {
                        TextField("Search customers...", text: $viewModel.customerSearch)
                            .onChange(of: viewModel.customerSearch) { _, _ in
                                Task { await viewModel.searchCustomers() }
                            }

                        if let customer = viewModel.selectedCustomer {
                            HStack {
                                Label(customer.fullName, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button("Change") {
                                    viewModel.selectedCustomer = nil
                                }
                                .controlSize(.small)
                            }
                        } else {
                            ForEach(viewModel.customers.prefix(5)) { customer in
                                Button {
                                    viewModel.selectedCustomer = customer
                                } label: {
                                    Text(customer.fullName)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Step 2: Select film
                    Section("2. Select Film") {
                        TextField("Search films...", text: $viewModel.filmSearch)
                            .onChange(of: viewModel.filmSearch) { _, _ in
                                Task { await viewModel.searchFilms() }
                            }

                        if let film = viewModel.selectedFilm {
                            HStack {
                                Label(film.title, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button("Change") {
                                    viewModel.selectedFilm = nil
                                    viewModel.selectedInventoryId = nil
                                    viewModel.availableInventory = []
                                }
                                .controlSize(.small)
                            }
                        } else {
                            ForEach(viewModel.films.prefix(5)) { film in
                                Button {
                                    viewModel.selectedFilm = film
                                    Task { await viewModel.loadInventory(filmId: film.id) }
                                } label: {
                                    HStack {
                                        Text(film.title)
                                        Spacer()
                                        Text(film.formattedRating)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Step 3: Select inventory
                    if viewModel.selectedFilm != nil {
                        Section("3. Select Copy") {
                            let available = viewModel.availableInventory.filter(\.available)
                            if available.isEmpty {
                                Text("No copies available")
                                    .foregroundStyle(.red)
                            } else {
                                Picker("Copy", selection: $viewModel.selectedInventoryId) {
                                    Text("Select...").tag(Int?.none)
                                    ForEach(available) { item in
                                        Text("Copy #\(item.id) — Store \(item.storeId)")
                                            .tag(Optional(item.id))
                                    }
                                }
                            }
                        }
                    }

                    // Step 4: Select staff
                    Section("4. Staff Member") {
                        Picker("Staff", selection: $viewModel.selectedStaffId) {
                            Text("Select...").tag(Int?.none)
                            ForEach(viewModel.staffMembers) { staff in
                                Text(staff.fullName).tag(Optional(staff.id))
                            }
                        }
                    }
                }
                .formStyle(.grouped)

                HStack {
                    Button("Reset") {
                        viewModel.resetNewRental()
                    }
                    .controlSize(.small)

                    Spacer()

                    Button("Create Rental") {
                        Task { await viewModel.createRental() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.selectedCustomer == nil ||
                        viewModel.selectedInventoryId == nil ||
                        viewModel.selectedStaffId == nil
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(minWidth: 350)
        }
        .navigationTitle("Rentals")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await viewModel.loadActiveRentals() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.activeRentals.isEmpty {
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
        .task {
            await viewModel.loadActiveRentals()
            await viewModel.loadStaff()
        }
    }
}
