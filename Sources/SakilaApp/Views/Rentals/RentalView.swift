// RentalView.swift
// The rental management view with two panels:
// - Left: Active rentals list with return buttons
// - Right: New rental creation wizard (customer → film → copy → staff)
// Uses an HSplitView for a resizable side-by-side layout.

import SwiftUI

/// Rental management view that displays active rentals and provides a new rental creation workflow.
/// The left panel shows all unreturned rentals with return actions.
/// The right panel provides a step-by-step form for creating new rentals.
struct RentalView: View {
    /// ViewModel managing rental data and the new rental creation flow
    @State private var viewModel = RentalViewModel()

    var body: some View {
        HSplitView {
            // MARK: - Left Panel: Active Rentals List
            VStack(alignment: .leading, spacing: 0) {
                // Header with title and count
                HStack {
                    Text("Active Rentals")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.activeRentals.count)")
                        .foregroundStyle(.secondary)
                }
                .padding()

                // List of active (unreturned) rentals
                List(viewModel.activeRentals) { rental in
                    HStack {
                        // Rental details: film title, customer name, date, and staff
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

                        // Return button to process the film return
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

            // MARK: - Right Panel: New Rental Creation Wizard
            VStack(alignment: .leading, spacing: 16) {
                Text("New Rental")
                    .font(.headline)
                    .padding(.horizontal)

                Form {
                    // Step 1: Search and select a customer
                    Section("1. Select Customer") {
                        TextField("Search customers...", text: $viewModel.customerSearch)
                            .onChange(of: viewModel.customerSearch) { _, _ in
                                Task { await viewModel.searchCustomers() }
                            }

                        // Show selected customer or search results
                        if let customer = viewModel.selectedCustomer {
                            // Customer selected — show confirmation with change option
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
                            // Show top 5 search results as selectable buttons
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

                    // Step 2: Search and select a film
                    Section("2. Select Film") {
                        TextField("Search films...", text: $viewModel.filmSearch)
                            .onChange(of: viewModel.filmSearch) { _, _ in
                                Task { await viewModel.searchFilms() }
                            }

                        // Show selected film or search results
                        if let film = viewModel.selectedFilm {
                            // Film selected — show confirmation with change option
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
                            // Show top 5 search results with rating info
                            ForEach(viewModel.films.prefix(5)) { film in
                                Button {
                                    viewModel.selectedFilm = film
                                    // Load inventory for the selected film
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

                    // Step 3: Select a specific inventory copy (shown after film selection)
                    if viewModel.selectedFilm != nil {
                        Section("3. Select Copy") {
                            let available = viewModel.availableInventory.filter(\.available)
                            if available.isEmpty {
                                Text("No copies available")
                                    .foregroundStyle(.red)
                            } else {
                                // Picker showing available copies with store info
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

                    // Step 4: Select the staff member processing the rental
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

                // Action buttons: Reset form and Create Rental
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
                    // Disabled until all required selections are made
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
            // Manual refresh button for the active rentals list
            ToolbarItem {
                Button {
                    Task { await viewModel.loadActiveRentals() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        // Loading spinner for initial load
        .overlay {
            if viewModel.isLoading && viewModel.activeRentals.isEmpty {
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
        // Load active rentals and staff list when the view first appears
        .task {
            await viewModel.loadActiveRentals()
            await viewModel.loadStaff()
        }
    }
}
