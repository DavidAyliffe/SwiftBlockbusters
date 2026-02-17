import Foundation

@Observable
@MainActor
final class CustomerViewModel {
    var customers: [Customer] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showingForm = false
    var editingCustomer: Customer?
    var cities: [(id: Int, name: String)] = []

    private let db = DatabaseService.shared

    func loadCustomers() async {
        isLoading = true
        errorMessage = nil
        do {
            customers = try await db.fetchCustomers(search: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadCities() async {
        do {
            cities = try await db.fetchCities()
        } catch {
            // Silently fail
        }
    }

    func addCustomer(firstName: String, lastName: String, email: String, storeId: Int, address: String, district: String, cityId: Int, postalCode: String, phone: String) async {
        errorMessage = nil
        do {
            try await db.addCustomer(
                firstName: firstName, lastName: lastName, email: email,
                storeId: storeId, address: address, district: district,
                cityId: cityId, postalCode: postalCode, phone: phone
            )
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCustomer(_ customer: Customer) async {
        errorMessage = nil
        do {
            try await db.updateCustomer(
                id: customer.id, firstName: customer.firstName,
                lastName: customer.lastName, email: customer.email ?? "",
                storeId: customer.storeId, active: customer.active
            )
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCustomer(id: Int) async {
        errorMessage = nil
        do {
            try await db.deleteCustomer(id: id)
            await loadCustomers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func beginAdd() {
        editingCustomer = nil
        showingForm = true
    }

    func beginEdit(_ customer: Customer) {
        editingCustomer = customer
        showingForm = true
    }
}
