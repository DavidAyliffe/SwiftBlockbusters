// Category.swift
// Data model representing a film genre/category in the Blockbusters database.
// Maps to the `category` table in MySQL.

import Foundation

/// Represents a film category (e.g., "Action", "Comedy", "Drama").
/// Used for filtering films and displaying genre information.
struct Category: Identifiable, Hashable {
    /// Unique category identifier from the database (category_id primary key)
    let id: Int
    /// Display name of the category (e.g., "Action", "Horror")
    var name: String
}
