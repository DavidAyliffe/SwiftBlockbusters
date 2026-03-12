// Staff.swift
// Data model representing a staff member in the Blockbusters database.
// Maps to the `staff` table with joined address/city information.

import Foundation

/// Represents a staff member who works at one of the rental stores.
/// Staff can process rentals, handle returns, and manage customer accounts.
struct Staff: Identifiable, Hashable {
    /// Unique staff identifier (staff_id primary key)
    let id: Int
    /// Staff member's first name
    var firstName: String
    /// Staff member's last name
    var lastName: String
    /// Staff member's email address (optional)
    var email: String?
    /// The store this staff member is assigned to (1 or 2)
    var storeId: Int
    /// Whether the staff member is currently active/employed
    var active: Bool
    /// Login username for the staff member
    var username: String

    // MARK: - Joined address fields (populated via SQL JOINs, not stored directly on staff table)

    /// Foreign key reference to the staff member's address record
    var addressId: Int
    /// Street address from the joined `address` table
    var address: String?
    /// District or region from the joined `address` table
    var district: String?
    /// City name from the joined `city` table
    var city: String?
    /// Phone number from the joined `address` table
    var phone: String?

    /// Computed convenience property that combines first and last name for display purposes.
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
