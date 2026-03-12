// Rental.swift
// Data model representing a rental transaction in the Blockbusters database.
// Maps to the `rental` table with joined customer, film, and staff display names.

import Foundation

/// Represents a rental transaction where a customer borrows a film copy.
/// Includes joined display fields for showing human-readable names in the UI.
struct Rental: Identifiable {
    /// Unique rental identifier (rental_id primary key)
    let id: Int
    /// Date and time the rental was created
    var rentalDate: Date
    /// Date and time the film was returned (nil if still rented out)
    var returnDate: Date?
    /// Foreign key to the specific inventory copy that was rented
    var inventoryId: Int
    /// Foreign key to the customer who rented the film
    var customerId: Int
    /// Foreign key to the staff member who processed the rental
    var staffId: Int

    // MARK: - Joined display fields (populated via SQL JOINs for UI display)

    /// Full name of the customer (e.g., "John Smith") — from joined customer table
    var customerName: String?
    /// Title of the rented film — from joined film table via inventory
    var filmTitle: String?
    /// Full name of the staff member who processed the rental — from joined staff table
    var staffName: String?

    /// Returns `true` if the rental has not yet been returned (returnDate is nil).
    var isActive: Bool {
        returnDate == nil
    }
}
