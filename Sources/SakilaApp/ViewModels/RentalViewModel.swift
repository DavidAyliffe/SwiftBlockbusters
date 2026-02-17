import Foundation

@Observable
@MainActor
final class RentalViewModel {
    var activeRentals: [Rental] = []
    var isLoading = false
    var errorMessage: String?

    // New rental flow
    var showingNewRental = false
    var customers: [Customer] = []
    var films: [Film] = []
    var availableInventory: [InventoryItem] = []
    var staffMembers: [Staff] = []
    var customerSearch = ""
    var filmSearch = ""
    var selectedCustomer: Customer?
    var selectedFilm: Film?
    var selectedInventoryId: Int?
    var selectedStaffId: Int?

    private let db = DatabaseService.shared

    func loadActiveRentals() async {
        isLoading = true
        errorMessage = nil
        do {
            activeRentals = try await db.fetchActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func processReturn(rentalId: Int) async {
        errorMessage = nil
        do {
            try await db.processReturn(rentalId: rentalId)
            await loadActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchCustomers() async {
        do {
            customers = try await db.fetchCustomers(search: customerSearch)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchFilms() async {
        do {
            films = try await db.fetchFilms(search: filmSearch)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadInventory(filmId: Int) async {
        do {
            availableInventory = try await db.fetchAvailableInventory(filmId: filmId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadStaff() async {
        do {
            staffMembers = try await db.fetchStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createRental() async {
        guard let inventoryId = selectedInventoryId,
              let customer = selectedCustomer,
              let staffId = selectedStaffId else {
            errorMessage = "Please select customer, film inventory, and staff member."
            return
        }
        errorMessage = nil
        do {
            try await db.createRental(inventoryId: inventoryId, customerId: customer.id, staffId: staffId)
            resetNewRental()
            await loadActiveRentals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func beginNewRental() {
        resetNewRental()
        showingNewRental = true
    }

    func resetNewRental() {
        showingNewRental = false
        selectedCustomer = nil
        selectedFilm = nil
        selectedInventoryId = nil
        selectedStaffId = nil
        customerSearch = ""
        filmSearch = ""
        customers = []
        films = []
        availableInventory = []
    }
}
