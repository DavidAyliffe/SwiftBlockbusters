// StaffListView.swift
// Displays a list of all staff members with add, edit, and delete functionality.
// Uses StaffFormView for add/edit operations via a sheet presentation.

import SwiftUI

/// Main staff list view with add, refresh, and context menu edit/delete actions.
struct StaffListView: View {
    /// ViewModel managing staff data and UI state
    @State private var viewModel = StaffViewModel()

    var body: some View {
        List {
            // Render each staff member as a row with context menu for edit/delete
            ForEach(viewModel.staffMembers) { staff in
                StaffRow(staff: staff)
                    .contextMenu {
                        Button("Edit") {
                            viewModel.beginEdit(staff)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteStaff(id: staff.id) }
                        }
                    }
            }
        }
        // Navigation title shows the current count of loaded staff members
        .navigationTitle("Staff (\(viewModel.staffMembers.count))")
        .toolbar {
            // Add staff button
            ToolbarItem {
                Button {
                    viewModel.beginAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Staff")
            }
            // Manual refresh button
            ToolbarItem {
                Button {
                    Task { await viewModel.loadStaff() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        // Loading spinner shown when initial load is in progress
        .overlay {
            if viewModel.isLoading && viewModel.staffMembers.isEmpty {
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
        // Add/edit staff form sheet
        .sheet(isPresented: $viewModel.showingForm) {
            StaffFormView(viewModel: viewModel)
        }
        // Load staff members when the view first appears
        .task {
            await viewModel.loadStaff()
        }
    }
}

/// A row component displaying a single staff member's information.
/// Shows the staff member's name, active status, username, email, store, and city.
struct StaffRow: View {
    /// The staff data to display
    let staff: Staff

    var body: some View {
        HStack {
            // Left side: name, status badge, username, and email
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(staff.fullName)
                        .font(.headline)
                    // Show an "Inactive" badge if the staff member is deactivated
                    if !staff.active {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 8) {
                    // Username displayed with @ prefix in blue
                    Text("@\(staff.username)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    if let email = staff.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Right side: store number and city
            VStack(alignment: .trailing, spacing: 2) {
                Text("Store \(staff.storeId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let city = staff.city {
                    Text(city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
