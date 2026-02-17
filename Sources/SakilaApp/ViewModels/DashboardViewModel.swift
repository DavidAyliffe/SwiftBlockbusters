import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var stats = DashboardStats()
    var isLoading = false
    var errorMessage: String?

    private let db = DatabaseService.shared

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
