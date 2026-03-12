// CustomerViewModel.swift
// ViewModel for the customer management section.
// Handles loading, searching, adding, editing, and deleting customers.
// Follows the MVVM pattern with @Observable for SwiftUI data binding.

import Foundation

/// ViewModel that manages customer data and UI state for the customer list and form views.
/// All methods are MainActor-isolated to ensure safe UI updates.
@Observable
@MainActor
final class CustomerViewModel {
    /// The currently loaded list of customers
    var customers: [Customer] = []
    /// Current search text for filtering customers by name or email
    var searchText = ""
    /// Whether a data loading operation is in progress (drives loading indicators)
    var isLoading = false
    /// Error message to display in an alert if an operation fails
    var errorMessage: String?
    /// Controls visibility of the add/edit customer form sheet
    var showingForm = false
    /// The customer being edited (nil when adding a new customer)
    var editingCustomer: Customer?
    /// List of available cities for the address form dropdown
    var cities: [(id: Int, name: String)] = []

    /// Reference to the shared database service for executing queries
    private let db = DatabaseService.shared

    /// Loads customers from the database, optionally filtered by the current search text.
    /// Updates the `customers` array and manages loading/error state.
    func loadCustomers() async {
        isLoading = true
        errorMessage = nil
        do {
            customers = try await db.fetchCustomers(search: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Loads the list of available cities for the address form's city picker.
    /// Silently fails if cities cannot be loaded (non-critical operation).
    func loadCities() async {
        do {
            cities = try await db.fetchCities()
        } catch {
            // Silently fail — city loading is not critical to the form
        }
    }

    /// Adds a new customer with the provided personal and address information.
    /// Reloads the customer list on success to reflect the new entry.
    /// - Parameters:
    ///   - firstName: Customer's first name
    ///   - lastName: Customer's last name
    ///   - email: Customer's email address
    ///   - storeId: Store the customer is registered at
    ///   - address: Street address
    ///   - district: District or region
    ///   - cityId: Foreign key to the city table
    ///   - postalCode: Postal/ZIP code
    ///   - phone: Phone number
    func addCustomer(firstName: String, lastName: String, email: String, storeId: Int, address: String, district: String, cityId: Int, postalCode: String, phone: String) async {
        errorMessage = nil
        do {
            try await db.addCustomer(
                firstName: firstName, lastName: lastName, email: email,
                storeId: storeId, address: address, district: district,
                cityId: cityId, postalCode: postalCode, phone: phone
            )
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates an existing customer's information in the database.
    /// Reloads the customer list on success to reflect the changes.
    /// - Parameter customer: The customer model with updated field values
    func updateCustomer(_ customer: Customer) async {
        errorMessage = nil
        do {
            try await db.updateCustomer(
                id: customer.id, firstName: customer.firstName,
                lastName: customer.lastName, email: customer.email ?? "",
                storeId: customer.storeId, active: customer.active
            )
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a customer and all their associated records from the database.
    /// Reloads the customer list on success to reflect the removal.
    /// - Parameter id: The customer_id to delete
    func deleteCustomer(id: Int) async {
        errorMessage = nil
        do {
            try await db.deleteCustomer(id: id)
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Prepares the UI state for adding a new customer (shows form with no pre-filled data).
    func beginAdd() {
        editingCustomer = nil
        showingForm = true
    }

    /// Prepares the UI state for editing an existing customer (shows form pre-filled with customer data).
    /// - Parameter customer: The customer to edit
    func beginEdit(_ customer: Customer) {
        editingCustomer = customer
        showingForm = true
    }
}
