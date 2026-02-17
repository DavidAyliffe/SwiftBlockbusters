import Foundation

struct DashboardStats {
    var totalFilms: Int = 0
    var totalCustomers: Int = 0
    var totalStaff: Int = 0
    var activeRentals: Int = 0
    var overdueRentals: Int = 0
    var totalRevenue: Decimal = 0

    var topFilms: [TopFilm] = []
    var recentRentals: [Rental] = []
}

struct TopFilm: Identifiable {
    let id: Int
    let title: String
    let rentalCount: Int
}
