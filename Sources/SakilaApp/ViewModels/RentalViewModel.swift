// RentalViewModel.swift
// ViewModel for the rental management section.
// Handles displaying active rentals, processing returns, and creating new rentals.
// The new rental flow is a multi-step process: select customer → select film → select copy → select staff.

import Foundation

/// ViewModel that manages rental operations including listing active rentals,
/// processing returns, and the multi-step new rental creation workflow.
@Observable
@MainActor
final class RentalViewModel {
    /// List of currently active (unreturned) rentals
    var activeRentals: [Rental] = []
    /// Whether a data loading operation is in progress
    var isLoading = false
    /// Error message to display if an operation fails
    var errorMessage: String?

    // MARK: - New Rental Flow State
    // These properties track the multi-step rental creation wizard.

    /// Whether the new rental panel is currently visible
    var showingNewRental = false
    /// Search results for the customer selection step
    var customers: [Customer] = []
    /// Search results for the film selection step
    var films: [Film] = []
    /// Available inventory copies for the selected film
    var availableInventory: [InventoryItem] = []
    /// Staff members available for assignment to the rental
    var staffMembers: [Staff] = []
    /// Search text for filtering customers in the new rental flow
    var customerSearch = ""
    /// Search text for filtering films in the new rental flow
    var filmSearch = ""
    /// The customer selected for the new rental (step 1)
    var selectedCustomer: Customer?
    /// The film selected for the new rental (step 2)
    var selectedFilm: Film?
    /// The specific inventory copy ID selected for the rental (step 3)
    var selectedInventoryId: Int?
    /// The staff member ID assigned to process the rental (step 4)
    var selectedStaffId: Int?

    /// Reference to the shared database service
    private let db = DatabaseService.shared

    /// Loads all active (unreturned) rentals from the database.
    /// Updates the `activeRentals` array and manages loading/error state.
    func loadActiveRentals() async {
        isLoading = true
        errorMessage = nil
        do {
            activeRentals = try await db.fetchActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Processes a film return by marking the rental as returned.
    /// Reloads the active rentals list to reflect the change.
    /// - Parameter rentalId: The rental_id to mark as returned
    func processReturn(rentalId: Int) async {
        errorMessage = nil
        do {
            try await db.processReturn(rentalId: rentalId)
            await loadActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Searches for customers matching the current `customerSearch` text.
    /// Used in step 1 of the new rental flow.
    func searchCustomers() async {
        do {
            customers = try await db.fetchCustomers(search: customerSearch)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Searches for films matching the current `filmSearch` text.
    /// Used in step 2 of the new rental flow.
    func searchFilms() async {
        do {
            films = try await db.fetchFilms(search: filmSearch)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Loads inventory availability for a specific film.
    /// Used in step 3 of the new rental flow to show available copies.
    /// - Parameter filmId: The film_id to load inventory for
    func loadInventory(filmId: Int) async {
        do {
            availableInventory = try await db.fetchAvailableInventory(filmId: filmId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Loads all staff members for the staff selection dropdown.
    /// Used in step 4 of the new rental flow.
    func loadStaff() async {
        do {
            staffMembers = try await db.fetchStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates a new rental transaction using the selected customer, inventory copy, and staff member.
    /// Validates that all required selections are made before proceeding.
    /// On success, resets the new rental form and reloads the active rentals list.
    func createRental() async {
        // Validate that all required selections have been made
        guard let inventoryId = selectedInventoryId,
              let customer = selectedCustomer,
              let staffId = selectedStaffId else {
            errorMessage = "Please select customer, film inventory, and staff member."
            return
        }
        errorMessage = nil
        do {
            try await db.createRental(inventoryId: inventoryId, customerId: customer.id, staffId: staffId)
            resetNewRental()
            await loadActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Initializes a new rental workflow by resetting all selections and showing the panel.
    func beginNewRental() {
        resetNewRental()
        showingNewRental = true
    }

    /// Resets all new rental form state back to defaults.
    /// Called after successful rental creation or when cancelling.
    func resetNewRental() {
        showingNewRental = false
        selectedCustomer = nil
        selectedFilm = nil
        selectedInventoryId = nil
        selectedStaffId = nil
        customerSearch = ""
        filmSearch = ""
        customers = []
        films = []
        availableInventory = []
    }
}
