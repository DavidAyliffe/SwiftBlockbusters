// Film.swift
// Data models for films and their associated detail, inventory, and store availability.
// Maps to the `film`, `inventory`, and related tables in the Blockbusters database.

import Foundation

/// Represents a film in the rental catalogue.
/// Contains all metadata from the `film` table needed for listing and detail views.
struct Film: Identifiable, Hashable {
    /// Unique film identifier (film_id primary key)
    let id: Int
    /// The title of the film
    var title: String
    /// A brief synopsis of the film (optional)
    var description: String?
    /// The year the film was released (optional)
    var releaseYear: Int?
    /// Foreign key to the language table (language the film is in)
    var languageId: Int
    /// Number of days the film can be rented before it becomes overdue
    var rentalDuration: Int
    /// Cost per rental transaction
    var rentalRate: Decimal
    /// Duration of the film in minutes (optional)
    var length: Int?
    /// Cost to replace a lost or damaged copy
    var replacementCost: Decimal
    /// MPAA rating (e.g., "G", "PG", "PG-13", "R", "NC-17") — optional
    var rating: String?
    /// Comma-separated special features (e.g., "Trailers,Commentaries") — optional
    var specialFeatures: String?

    /// Returns the film's rating for display, defaulting to "NR" (Not Rated) if nil.
    var formattedRating: String {
        rating ?? "NR"
    }

    /// Returns a human-readable duration string (e.g., "1h 42m" or "30m").
    /// Returns "N/A" if the length is not set.
    var formattedLength: String {
        guard let length else { return "N/A" }
        let hours = length / 60
        let minutes = length % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

/// Extended film information including actors, categories, and inventory.
/// Used on the film detail page to show a comprehensive view of a single film.
struct FilmDetail {
    /// The core film data
    let film: Film
    /// Actors who appear in this film (from the film_actor join table)
    var actors: [Actor]
    /// Categories/genres assigned to this film (from the film_category join table)
    var categories: [Category]
    /// Inventory counts broken down by store location
    var inventoryByStore: [StoreInventory]
}

/// Inventory availability summary for a single store.
/// Shows how many total and available copies exist at that store.
struct StoreInventory: Identifiable {
    /// The store identifier
    let storeId: Int
    /// Total number of copies at this store
    let totalCount: Int
    /// Number of copies currently available (not rented out)
    let availableCount: Int

    /// Uses storeId as the Identifiable id for SwiftUI list rendering
    var id: Int { storeId }
}

/// Represents a single physical inventory item (copy of a film).
/// Used when selecting which specific copy to rent out.
struct InventoryItem: Identifiable {
    /// Unique inventory identifier (inventory_id primary key)
    let id: Int
    /// The store this copy belongs to
    let storeId: Int
    /// The title of the film this copy is for
    let filmTitle: String
    /// Whether this copy is currently available for rental
    let available: Bool
}
