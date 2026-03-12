// Customer.swift
// Data model representing a customer in the Blockbusters database.
// Maps to the `customer` table with joined address/city information.

import Foundation

/// Represents a customer who can rent films from the store.
/// Includes both core customer fields and joined address data for display.
struct Customer: Identifiable, Hashable {
    /// Unique customer identifier from the database (customer_id primary key)
    let id: Int
    /// The store this customer is registered at (1 or 2)
    var storeId: Int
    /// Customer's first name
    var firstName: String
    /// Customer's last name
    var lastName: String
    /// Customer's email address (optional — some customers may not have one)
    var email: String?
    /// Foreign key reference to the customer's address record
    var addressId: Int
    /// Whether the customer account is currently active
    var active: Bool

    // MARK: - Joined address fields (populated via SQL JOINs, not stored directly on customer table)

    /// Street address from the joined `address` table
    var address: String?
    /// District or region from the joined `address` table
    var district: String?
    /// City name from the joined `city` table
    var city: String?
    /// Postal/ZIP code from the joined `address` table
    var postalCode: String?
    /// Phone number from the joined `address` table
    var phone: String?

    /// Computed convenience property that combines first and last name for display purposes.
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
