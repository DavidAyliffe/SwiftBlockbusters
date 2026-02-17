import Foundation

@Observable
@MainActor
final class StaffViewModel {
    var staffMembers: [Staff] = []
    var isLoading = false
    var errorMessage: String?
    var showingForm = false
    var editingStaff: Staff?

    private let db = DatabaseService.shared

    func loadStaff() async {
        isLoading = true
        errorMessage = nil
        do {
            staffMembers = try await db.fetchStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addStaff(firstName: String, lastName: String, email: String, storeId: Int, username: String, addressId: Int) async {
        errorMessage = nil
        do {
            try await db.addStaff(
                firstName: firstName, lastName: lastName, email: email,
                storeId: storeId, username: username, addressId: addressId
            )
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStaff(_ staff: Staff) async {
        errorMessage = nil
        do {
            try await db.updateStaff(
                id: staff.id, firstName: staff.firstName,
                lastName: staff.lastName, email: staff.email ?? "",
                storeId: staff.storeId, username: staff.username,
                active: staff.active
            )
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteStaff(id: Int) async {
        errorMessage = nil
        do {
            try await db.deleteStaff(id: id)
            await loadStaff()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func beginAdd() {
        editingStaff = nil
        showingForm = true
    }

    func beginEdit(_ staff: Staff) {
        editingStaff = staff
        showingForm = true
    }
}
