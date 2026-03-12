// DashboardViewModel.swift
// ViewModel for the dashboard overview screen.
// Loads aggregated business statistics from the database.

import Foundation

/// ViewModel that manages dashboard statistics loading and error state.
/// Fetches aggregated metrics (film counts, revenue, top films, etc.) for display.
@Observable
@MainActor
final class DashboardViewModel {
    /// The current dashboard statistics (populated after a successful load)
    var stats = DashboardStats()
    /// Whether statistics are currently being loaded from the database
    var isLoading = false
    /// Error message to display if the stats query fails
    var errorMessage: String?

    /// Reference to the shared database service
    private let db = DatabaseService.shared

    /// Loads all dashboard statistics from the database.
    /// This triggers multiple queries (counts, sums, top films, recent rentals).
    func loadStats() async {
        isLoading = true
        errorMessage = nil
        do {
            stats = try await db.fetchDashboardStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
