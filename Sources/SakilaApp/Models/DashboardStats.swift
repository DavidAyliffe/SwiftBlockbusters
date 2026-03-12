// DashboardStats.swift
// Data models for the dashboard overview, aggregating key business metrics.
// Populated by multiple database queries in DatabaseService.fetchDashboardStats().

import Foundation

/// Aggregated statistics displayed on the main dashboard.
/// Provides a snapshot of the current state of the rental business.
struct DashboardStats {
    /// Total number of films in the catalogue
    var totalFilms: Int = 0
    /// Total number of registered customers
    var totalCustomers: Int = 0
    /// Total number of staff members
    var totalStaff: Int = 0
    /// Number of rentals that have not yet been returned
    var activeRentals: Int = 0
    /// Number of rentals past their expected return date
    var overdueRentals: Int = 0
    /// Cumulative revenue from all payments
    var totalRevenue: Decimal = 0

    /// The top 5 most-rented films, ordered by rental count descending
    var topFilms: [TopFilm] = []
    /// The 10 most recent rental transactions
    var recentRentals: [Rental] = []
}

/// Represents a film ranked by its total number of rentals.
/// Used in the "Top 5 Rented Films" dashboard section.
struct TopFilm: Identifiable {
    /// Unique film identifier (film_id)
    let id: Int
    /// Title of the film
    let title: String
    /// Total number of times this film has been rented
    let rentalCount: Int
}
