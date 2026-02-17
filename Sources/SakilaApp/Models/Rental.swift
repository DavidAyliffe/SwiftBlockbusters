import Foundation

struct Rental: Identifiable {
    let id: Int
    var rentalDate: Date
    var returnDate: Date?
    var inventoryId: Int
    var customerId: Int
    var staffId: Int

    // Joined display fields
    var customerName: String?
    var filmTitle: String?
    var staffName: String?

    var isActive: Bool {
        returnDate == nil
    }
}
