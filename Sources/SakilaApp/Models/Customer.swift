import Foundation

struct Customer: Identifiable, Hashable {
    let id: Int
    var storeId: Int
    var firstName: String
    var lastName: String
    var email: String?
    var addressId: Int
    var active: Bool

    // Joined address fields
    var address: String?
    var district: String?
    var city: String?
    var postalCode: String?
    var phone: String?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
