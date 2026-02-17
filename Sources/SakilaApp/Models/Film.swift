import Foundation

struct Film: Identifiable, Hashable {
    let id: Int
    var title: String
    var description: String?
    var releaseYear: Int?
    var languageId: Int
    var rentalDuration: Int
    var rentalRate: Decimal
    var length: Int?
    var replacementCost: Decimal
    var rating: String?
    var specialFeatures: String?

    var formattedRating: String {
        rating ?? "NR"
    }

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

struct FilmDetail {
    let film: Film
    var actors: [Actor]
    var categories: [Category]
    var inventoryByStore: [StoreInventory]
}

struct StoreInventory: Identifiable {
    let storeId: Int
    let totalCount: Int
    let availableCount: Int

    var id: Int { storeId }
}

struct InventoryItem: Identifiable {
    let id: Int
    let storeId: Int
    let filmTitle: String
    let available: Bool
}
