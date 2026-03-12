// Actor.swift
// Data model representing an actor in the Blockbusters database.
// Maps to the `actor` table in MySQL.

import Foundation

/// Represents an actor who appears in one or more films.
/// Conforms to `Identifiable` for use in SwiftUI lists and `Hashable` for selection support.
struct Actor: Identifiable, Hashable {
    /// Unique actor identifier from the database (actor_id primary key)
    let id: Int
    /// The actor's first name
    var firstName: String
    /// The actor's last name
    var lastName: String

    /// Computed convenience property that combines first and last name for display purposes.
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
