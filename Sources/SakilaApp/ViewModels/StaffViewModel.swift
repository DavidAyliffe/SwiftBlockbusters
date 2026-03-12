// StaffViewModel.swift
// ViewModel for the staff management section.
// Handles loading, adding, editing, and deleting staff members.

import Foundation

/// ViewModel that manages staff data and UI state for the staff list and form views.
/// All methods are MainActor-isolated to ensure safe UI updates.
@Observable
@MainActor
final class StaffViewModel {
    /// The currently loaded list of staff members
    var staffMembers: [Staff] = []
    /// Whether a data loading operation is in progress
    var isLoading = false
    /// Error message to display in an alert if an operation fails
    var errorMessage: String?
    /// Controls visibility of the add/edit staff form sheet
    var showingForm = false
    /// The staff member being edited (nil when adding a new staff member)
    var editingStaff: Staff?

    /// Reference to the shared database service
    private let db = DatabaseService.shared

    /// Loads all staff members from the database.
    /// Updates the `staffMembers` array and manages loading/error state.
    func loadStaff() async {
        isLoading = true
        errorMessage = nil
        do {
            staffMembers = try await db.fetchStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Adds a new staff member to the database.
    /// Reloads the staff list on success to reflect the new entry.
    /// - Parameters:
    ///   - firstName: Staff member's first name
    ///   - lastName: Staff member's last name
    ///   - email: Staff member's email address
    ///   - storeId: Store assignment
    ///   - username: Login username
    ///   - addressId: Foreign key to an existing address record
    func addStaff(firstName: String, lastName: String, email: String, storeId: Int, username: String, addressId: Int) async {
        errorMessage = nil
        do {
            try await db.addStaff(
                firstName: firstName, lastName: lastName, email: email,
                storeId: storeId, username: username, addressId: addressId
            )
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates an existing staff member's information in the database.
    /// Reloads the staff list on success to reflect the changes.
    /// - Parameter staff: The staff model with updated field values
    func updateStaff(_ staff: Staff) async {
        errorMessage = nil
        do {
            try await db.updateStaff(
                id: staff.id, firstName: staff.firstName,
                lastName: staff.lastName, email: staff.email ?? "",
                storeId: staff.storeId, username: staff.username,
                active: staff.active
            )
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a staff member and their associated records from the database.
    /// Reloads the staff list on success to reflect the removal.
    /// - Parameter id: The staff_id to delete
    func deleteStaff(id: Int) async {
        errorMessage = nil
        do {
            try await db.deleteStaff(id: id)
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Prepares the UI state for adding a new staff member (shows form with no pre-filled data).
    func beginAdd() {
        editingStaff = nil
        showingForm = true
    }

    /// Prepares the UI state for editing an existing staff member (shows form pre-filled with staff data).
    /// - Parameter staff: The staff member to edit
    func beginEdit(_ staff: Staff) {
        editingStaff = staff
        showingForm = true
    }
}
