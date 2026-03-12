// FilmViewModel.swift
// ViewModel for the film browsing and detail section.
// Handles film listing with search/filter, category loading, and film detail retrieval.

import Foundation

/// ViewModel that manages film listing, filtering, and detail loading.
/// Supports searching by title, filtering by category and MPAA rating.
@Observable
@MainActor
final class FilmViewModel {
    /// The currently loaded list of films matching the active filters
    var films: [Film] = []
    /// Detailed information for the currently selected film (actors, categories, inventory)
    var selectedFilmDetail: FilmDetail?
    /// Available categories for the category filter dropdown
    var categories: [Category] = []
    /// Current search text for title-based filtering
    var searchText = ""
    /// Currently selected category filter (nil means "All Categories")
    var selectedCategory: String?
    /// Currently selected MPAA rating filter (nil means "All Ratings")
    var selectedRating: String?
    /// Whether a data loading operation is in progress
    var isLoading = false
    /// Error message to display if an operation fails
    var errorMessage: String?

    /// Available MPAA rating options for the rating filter dropdown
    static let ratings = ["G", "PG", "PG-13", "R", "NC-17"]

    /// Reference to the shared database service
    private let db = DatabaseService.shared

    /// Loads films from the database using the current search text and filter selections.
    /// Updates the `films` array and manages loading/error state.
    func loadFilms() async {
        isLoading = true
        errorMessage = nil
        do {
            films = try await db.fetchFilms(search: searchText, category: selectedCategory, rating: selectedRating)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Loads all available film categories for the filter dropdown.
    /// Silently fails since categories are a non-critical UI enhancement.
    func loadCategories() async {
        do {
            categories = try await db.fetchCategories()
        } catch {
            // Silently fail — category loading is not critical
        }
    }

    /// Loads comprehensive detail for a specific film (cast, genres, inventory).
    /// Populates `selectedFilmDetail` for the film detail view.
    /// - Parameter filmId: The film_id to load detail for
    func loadFilmDetail(filmId: Int) async {
        errorMessage = nil
        do {
            selectedFilmDetail = try await db.fetchFilmDetail(filmId: filmId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
