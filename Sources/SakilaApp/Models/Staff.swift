import Foundation

struct Staff: Identifiable, Hashable {
    let id: Int
    var firstName: String
    var lastName: String
    var email: String?
    var storeId: Int
    var active: Bool
    var username: String

    // Joined address fields
    var addressId: Int
    var address: String?
    var district: String?
    var city: String?
    var phone: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
