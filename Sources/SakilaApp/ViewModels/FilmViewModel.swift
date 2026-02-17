import Foundation

@Observable
@MainActor
final class FilmViewModel {
    var films: [Film] = []
    var selectedFilmDetail: FilmDetail?
    var categories: [Category] = []
    var searchText = ""
    var selectedCategory: String?
    var selectedRating: String?
    var isLoading = false
    var errorMessage: String?

    static let ratings = ["G", "PG", "PG-13", "R", "NC-17"]

    private let db = DatabaseService.shared

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

    func loadCategories() async {
        do {
            categories = try await db.fetchCategories()
        } catch {
            // Silently fail for categories
        }
    }

    func loadFilmDetail(filmId: Int) async {
        errorMessage = nil
        do {
            selectedFilmDetail = try await db.fetchFilmDetail(filmId: filmId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
