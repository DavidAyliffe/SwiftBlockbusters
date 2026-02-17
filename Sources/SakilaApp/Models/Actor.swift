import Foundation

struct Actor: Identifiable, Hashable {
    let id: Int
    var firstName: String
    var lastName: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
