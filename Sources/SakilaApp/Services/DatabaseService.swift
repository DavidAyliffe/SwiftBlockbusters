import Foundation
import MySQLNIO
import NIOPosix
import Logging

@Observable
final class DatabaseService: Sendable {
    static let shared = DatabaseService()

    // Connection state — accessed on MainActor for UI binding
    @MainActor var isConnected = false
    @MainActor var connectionError: String?

    // Connection config defaults
    @MainActor var host = "127.0.0.1"
    @MainActor var port = 3306
    @MainActor var username = "root"
    @MainActor var password = "rootroot"
    @MainActor var database = "blockbusters"

    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private nonisolated(unsafe) var _connection: MySQLConnection?

    private init() {}

    // MARK: - Connection Management

    @MainActor
    func connect() async {
        connectionError = nil
        let h = host
        let p = port
        let u = username
        let pw = password
        let db = database

        do {
            let conn = try await connectToMySQL(host: h, port: p, username: u, password: pw, database: db)
            _connection = conn
            isConnected = true
        } catch {
            connectionError = error.localizedDescription
            isConnected = false
        }
    }

    private func connectToMySQL(host: String, port: Int, username: String, password: String, database: String) async throws -> MySQLConnection {
        var logger = Logger(label: "sakila-app")
        logger.logLevel = .warning

        let eventLoop = eventLoopGroup.next()
        let conn = try await MySQLConnection.connect(
            to: .makeAddressResolvingHost(host, port: port),
            username: username,
            database: database,
            password: password,
            tlsConfiguration: nil,
            logger: logger,
            on: eventLoop
        ).get()
        return conn
    }

    @MainActor
    func disconnect() async {
        guard let conn = _connection else { return }
        _connection = nil
        try? await conn.close().get()
        isConnected = false
    }

    private func requireConnection() throws -> MySQLConnection {
        guard let conn = _connection else {
            throw DatabaseError.notConnected
        }
        return conn
    }

    // MARK: - Film Queries

    func fetchFilms(search: String = "", category: String? = nil, rating: String? = nil) async throws -> [Film] {
        let conn = try requireConnection()

        var sql = """
            SELECT DISTINCT f.film_id, f.title, f.description, f.release_year,
                   f.language_id, f.rental_duration, f.rental_rate, f.length,
                   f.replacement_cost, f.rating, f.special_features
            FROM film f
            """

        var binds: [MySQLData] = []
        var conditions: [String] = []

        if category != nil {
            sql += """
                 JOIN film_category fc ON f.film_id = fc.film_id
                 JOIN category c ON fc.category_id = c.category_id
                """
        }

        if !search.isEmpty {
            conditions.append("f.title LIKE ?")
            binds.append(.init(string: "%\(search)%"))
        }

        if let category, !category.isEmpty {
            conditions.append("c.name = ?")
            binds.append(.init(string: category))
        }

        if let rating, !rating.isEmpty {
            conditions.append("f.rating = ?")
            binds.append(.init(string: rating))
        }

        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }

        sql += " ORDER BY f.title LIMIT 500"

        let rows = try await conn.query(sql, binds).get()
        return rows.map { row in
            Film(
                id: row.column("film_id")?.int ?? 0,
                title: row.column("title")?.string ?? "",
                description: row.column("description")?.string,
                releaseYear: row.column("release_year")?.int,
                languageId: row.column("language_id")?.int ?? 1,
                rentalDuration: row.column("rental_duration")?.int ?? 3,
                rentalRate: Decimal(string: row.column("rental_rate")?.string ?? "0") ?? 0,
                length: row.column("length")?.int,
                replacementCost: Decimal(string: row.column("replacement_cost")?.string ?? "0") ?? 0,
                rating: row.column("rating")?.string,
                specialFeatures: row.column("special_features")?.string
            )
        }
    }

    func fetchFilmDetail(filmId: Int) async throws -> FilmDetail {
        let conn = try requireConnection()

        // Fetch the film
        let filmRows = try await conn.query(
            "SELECT * FROM film WHERE film_id = ?",
            [.init(int: filmId)]
        ).get()

        guard let row = filmRows.first else {
            throw DatabaseError.notFound
        }

        let film = Film(
            id: row.column("film_id")?.int ?? 0,
            title: row.column("title")?.string ?? "",
            description: row.column("description")?.string,
            releaseYear: row.column("release_year")?.int,
            languageId: row.column("language_id")?.int ?? 1,
            rentalDuration: row.column("rental_duration")?.int ?? 3,
            rentalRate: Decimal(string: row.column("rental_rate")?.string ?? "0") ?? 0,
            length: row.column("length")?.int,
            replacementCost: Decimal(string: row.column("replacement_cost")?.string ?? "0") ?? 0,
            rating: row.column("rating")?.string,
            specialFeatures: row.column("special_features")?.string
        )

        // Fetch actors
        let actorRows = try await conn.query("""
            SELECT a.actor_id, a.first_name, a.last_name
            FROM actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            WHERE fa.film_id = ?
            ORDER BY a.last_name, a.first_name
            """, [.init(int: filmId)]).get()

        let actors = actorRows.map { r in
            Actor(
                id: r.column("actor_id")?.int ?? 0,
                firstName: r.column("first_name")?.string ?? "",
                lastName: r.column("last_name")?.string ?? ""
            )
        }

        // Fetch categories
        let catRows = try await conn.query("""
            SELECT c.category_id, c.name
            FROM category c
            JOIN film_category fc ON c.category_id = fc.category_id
            WHERE fc.film_id = ?
            """, [.init(int: filmId)]).get()

        let categories = catRows.map { r in
            Category(
                id: r.column("category_id")?.int ?? 0,
                name: r.column("name")?.string ?? ""
            )
        }

        // Fetch inventory by store
        let invRows = try await conn.query("""
            SELECT i.store_id,
                   COUNT(*) as total,
                   SUM(CASE WHEN r.rental_id IS NULL THEN 1 ELSE 0 END) as available
            FROM inventory i
            LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.returned_date IS NULL
            WHERE i.film_id = ?
            GROUP BY i.store_id
            """, [.init(int: filmId)]).get()

        let inventory = invRows.map { r in
            StoreInventory(
                storeId: r.column("store_id")?.int ?? 0,
                totalCount: Int(r.column("total")?.string ?? "0") ?? 0,
                availableCount: Int(r.column("available")?.string ?? "0") ?? 0
            )
        }

        return FilmDetail(film: film, actors: actors, categories: categories, inventoryByStore: inventory)
    }

    func fetchCategories() async throws -> [Category] {
        let conn = try requireConnection()
        let rows = try await conn.query("SELECT category_id, name FROM category ORDER BY name").get()
        return rows.map { r in
            Category(id: r.column("category_id")?.int ?? 0, name: r.column("name")?.string ?? "")
        }
    }

    // MARK: - Customer Queries

    func fetchCustomers(search: String = "") async throws -> [Customer] {
        let conn = try requireConnection()

        var sql = """
            SELECT c.customer_id, c.store_id, c.first_name, c.last_name, c.email,
                   c.address_id, c.active,
                   a.address, a.district, ci.name, a.postal_code, a.phone
            FROM customer c
            JOIN address a ON c.address_id = a.address_id
            JOIN city ci ON a.city_id = ci.city_id
            """
        var binds: [MySQLData] = []

        if !search.isEmpty {
            sql += " WHERE c.first_name LIKE ? OR c.last_name LIKE ? OR c.email LIKE ?"
            let pattern = MySQLData(string: "%\(search)%")
            binds = [pattern, pattern, pattern]
        }

        sql += " ORDER BY c.last_name, c.first_name LIMIT 500"

        let rows = try await conn.query(sql, binds).get()
        return rows.map { r in
            Customer(
                id: r.column("customer_id")?.int ?? 0,
                storeId: r.column("store_id")?.int ?? 1,
                firstName: r.column("first_name")?.string ?? "",
                lastName: r.column("last_name")?.string ?? "",
                email: r.column("email")?.string,
                addressId: r.column("address_id")?.int ?? 0,
                active: (r.column("active")?.int ?? 1) == 1,
                address: r.column("address")?.string,
                district: r.column("district")?.string,
                city: r.column("city")?.string,
                postalCode: r.column("postal_code")?.string,
                phone: r.column("phone")?.string
            )
        }
    }

    func addCustomer(firstName: String, lastName: String, email: String, storeId: Int, address: String, district: String, cityId: Int, postalCode: String, phone: String) async throws {
        let conn = try requireConnection()

        // Insert address first
        _ = try await conn.query("""
            INSERT INTO address (address, district, city_id, postal_code, phone, location)
            VALUES (?, ?, ?, ?, ?, ST_GeomFromText('POINT(0 0)'))
            """, [
                .init(string: address),
                .init(string: district),
                .init(int: cityId),
                .init(string: postalCode),
                .init(string: phone)
            ]).get()

        // Get the address ID
        let addrRows = try await conn.query("SELECT LAST_INSERT_ID() as id").get()
        guard let addressId = addrRows.first?.column("id")?.int else {
            throw DatabaseError.insertFailed
        }

        // Insert customer
        _ = try await conn.query("""
            INSERT INTO customer (store_id, first_name, last_name, email, address_id, active, create_date)
            VALUES (?, ?, ?, ?, ?, 1, NOW())
            """, [
                .init(int: storeId),
                .init(string: firstName),
                .init(string: lastName),
                .init(string: email),
                .init(int: addressId)
            ]).get()
    }

    func updateCustomer(id: Int, firstName: String, lastName: String, email: String, storeId: Int, active: Bool) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("""
            UPDATE customer SET first_name = ?, last_name = ?, email = ?, store_id = ?, active = ?
            WHERE customer_id = ?
            """, [
                .init(string: firstName),
                .init(string: lastName),
                .init(string: email),
                .init(int: storeId),
                .init(int: active ? 1 : 0),
                .init(int: id)
            ]).get()
    }

    func deleteCustomer(id: Int) async throws {
        let conn = try requireConnection()
        // Delete rentals and payments first due to FK constraints
        _ = try await conn.query("DELETE FROM payment WHERE customer_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM rental WHERE customer_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM customer WHERE customer_id = ?", [.init(int: id)]).get()
    }

    // MARK: - Staff Queries

    func fetchStaff() async throws -> [Staff] {
        let conn = try requireConnection()
        let rows = try await conn.query("""
            SELECT s.staff_id, s.first_name, s.last_name, s.email, s.store_id,
                   s.active, s.username, s.address_id,
                   a.address, a.district, ci.name, a.phone
            FROM staff s
            JOIN address a ON s.address_id = a.address_id
            JOIN city ci ON a.city_id = ci.city_id
            ORDER BY s.last_name, s.first_name
            """).get()
        return rows.map { r in
            Staff(
                id: r.column("staff_id")?.int ?? 0,
                firstName: r.column("first_name")?.string ?? "",
                lastName: r.column("last_name")?.string ?? "",
                email: r.column("email")?.string,
                storeId: r.column("store_id")?.int ?? 1,
                active: (r.column("active")?.int ?? 1) == 1,
                username: r.column("username")?.string ?? "",
                addressId: r.column("address_id")?.int ?? 0,
                address: r.column("address")?.string,
                district: r.column("district")?.string,
                city: r.column("city")?.string,
                phone: r.column("phone")?.string
            )
        }
    }

    func addStaff(firstName: String, lastName: String, email: String, storeId: Int, username: String, addressId: Int) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("""
            INSERT INTO staff (first_name, last_name, email, store_id, active, username, address_id)
            VALUES (?, ?, ?, ?, 1, ?, ?)
            """, [
                .init(string: firstName),
                .init(string: lastName),
                .init(string: email),
                .init(int: storeId),
                .init(string: username),
                .init(int: addressId)
            ]).get()
    }

    func updateStaff(id: Int, firstName: String, lastName: String, email: String, storeId: Int, username: String, active: Bool) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("""
            UPDATE staff SET first_name = ?, last_name = ?, email = ?, store_id = ?, username = ?, active = ?
            WHERE staff_id = ?
            """, [
                .init(string: firstName),
                .init(string: lastName),
                .init(string: email),
                .init(int: storeId),
                .init(string: username),
                .init(int: active ? 1 : 0),
                .init(int: id)
            ]).get()
    }

    func deleteStaff(id: Int) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("DELETE FROM payment WHERE staff_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM rental WHERE staff_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM staff WHERE staff_id = ?", [.init(int: id)]).get()
    }

    // MARK: - Rental Queries

    func fetchActiveRentals() async throws -> [Rental] {
        let conn = try requireConnection()
        let rows = try await conn.query("""
            SELECT r.rental_id, r.rental_date, r.returned_date, r.inventory_id,
                   r.customer_id, r.staff_id,
                   CONCAT(c.first_name, ' ', c.last_name) as customer_name,
                   f.title as film_title,
                   CONCAT(s.first_name, ' ', s.last_name) as staff_name
            FROM rental r
            JOIN customer c ON r.customer_id = c.customer_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN staff s ON r.staff_id = s.staff_id
            WHERE r.returned_date IS NULL
            ORDER BY r.rental_date DESC
            LIMIT 500
            """).get()
        return rows.map { parseRentalRow($0) }
    }

    func fetchRecentRentals(limit: Int = 10) async throws -> [Rental] {
        let conn = try requireConnection()
        let rows = try await conn.query("""
            SELECT r.rental_id, r.rental_date, r.returned_date, r.inventory_id,
                   r.customer_id, r.staff_id,
                   CONCAT(c.first_name, ' ', c.last_name) as customer_name,
                   f.title as film_title,
                   CONCAT(s.first_name, ' ', s.last_name) as staff_name
            FROM rental r
            JOIN customer c ON r.customer_id = c.customer_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN staff s ON r.staff_id = s.staff_id
            ORDER BY r.rental_date DESC
            LIMIT ?
            """, [.init(int: limit)]).get()
        return rows.map { parseRentalRow($0) }
    }

    func createRental(inventoryId: Int, customerId: Int, staffId: Int) async throws {
        let conn = try requireConnection()

        // Insert rental
        _ = try await conn.query("""
            INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
            VALUES (NOW(), ?, ?, ?)
            """, [
                .init(int: inventoryId),
                .init(int: customerId),
                .init(int: staffId)
            ]).get()

        // Insert a payment record
        let rentalRows = try await conn.query("SELECT LAST_INSERT_ID() as id").get()
        guard let rentalId = rentalRows.first?.column("id")?.int else { return }

        // Get rental rate for this film
        let rateRows = try await conn.query("""
            SELECT f.rental_rate FROM film f
            JOIN inventory i ON f.film_id = i.film_id
            WHERE i.inventory_id = ?
            """, [.init(int: inventoryId)]).get()
        let rate = rateRows.first?.column("rental_rate")?.string ?? "4.99"

        _ = try await conn.query("""
            INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
            VALUES (?, ?, ?, ?, NOW())
            """, [
                .init(int: customerId),
                .init(int: staffId),
                .init(int: rentalId),
                .init(string: rate)
            ]).get()
    }

    func processReturn(rentalId: Int) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("""
            UPDATE rental SET returned_date = NOW() WHERE rental_id = ?
            """, [.init(int: rentalId)]).get()
    }

    func fetchAvailableInventory(filmId: Int) async throws -> [InventoryItem] {
        let conn = try requireConnection()
        let rows = try await conn.query("""
            SELECT i.inventory_id, i.store_id, f.title,
                   CASE WHEN r.rental_id IS NULL THEN 1 ELSE 0 END as available
            FROM inventory i
            JOIN film f ON i.film_id = f.film_id
            LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.returned_date IS NULL
            WHERE i.film_id = ?
            ORDER BY i.store_id, i.inventory_id
            """, [.init(int: filmId)]).get()
        return rows.map { r in
            InventoryItem(
                id: r.column("inventory_id")?.int ?? 0,
                storeId: r.column("store_id")?.int ?? 0,
                filmTitle: r.column("title")?.string ?? "",
                available: (r.column("available")?.int ?? 0) == 1
            )
        }
    }

    // MARK: - Dashboard Queries

    func fetchDashboardStats() async throws -> DashboardStats {
        let conn = try requireConnection()

        let filmCount = try await conn.query("SELECT COUNT(*) as cnt FROM film").get()
        let custCount = try await conn.query("SELECT COUNT(*) as cnt FROM customer").get()
        let staffCount = try await conn.query("SELECT COUNT(*) as cnt FROM staff").get()
        let activeRentals = try await conn.query("SELECT COUNT(*) as cnt FROM rental WHERE returned_date IS NULL").get()
        let overdueRentals = try await conn.query("""
            SELECT COUNT(*) as cnt FROM rental r
            JOIN film f ON r.inventory_id = f.film_id
            WHERE r.returned_date IS NULL
            AND DATE_ADD(r.rental_date, INTERVAL f.rental_duration DAY) < NOW()
            """).get()
        let revenue = try await conn.query("SELECT COALESCE(SUM(amount), 0) as total FROM payment").get()

        let topFilmsRows = try await conn.query("""
            SELECT f.film_id, f.title, COUNT(r.rental_id) as rental_count
            FROM film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
            GROUP BY f.film_id, f.title
            ORDER BY rental_count DESC
            LIMIT 5
            """).get()

        let topFilms = topFilmsRows.map { r in
            TopFilm(
                id: r.column("film_id")?.int ?? 0,
                title: r.column("title")?.string ?? "",
                rentalCount: Int(r.column("rental_count")?.string ?? "0") ?? 0
            )
        }

        let recentRentals = try await fetchRecentRentals(limit: 10)

        return DashboardStats(
            totalFilms: Int(filmCount.first?.column("cnt")?.string ?? "0") ?? 0,
            totalCustomers: Int(custCount.first?.column("cnt")?.string ?? "0") ?? 0,
            totalStaff: Int(staffCount.first?.column("cnt")?.string ?? "0") ?? 0,
            activeRentals: Int(activeRentals.first?.column("cnt")?.string ?? "0") ?? 0,
            overdueRentals: Int(overdueRentals.first?.column("cnt")?.string ?? "0") ?? 0,
            totalRevenue: Decimal(string: revenue.first?.column("total")?.string ?? "0") ?? 0,
            topFilms: topFilms,
            recentRentals: recentRentals
        )
    }

    func fetchCities() async throws -> [(id: Int, name: String)] {
        let conn = try requireConnection()
        let rows = try await conn.query("SELECT city_id, city FROM city ORDER BY city LIMIT 600").get()
        return rows.map { r in
            (id: r.column("city_id")?.int ?? 0, name: r.column("city")?.string ?? "")
        }
    }

    // MARK: - Helpers

    private func parseRentalRow(_ r: MySQLRow) -> Rental {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return Rental(
            id: r.column("rental_id")?.int ?? 0,
            rentalDate: r.column("rental_date")?.string.flatMap { dateFormatter.date(from: $0) } ?? Date(),
            returnDate: r.column("returned_date")?.string.flatMap { dateFormatter.date(from: $0) },
            inventoryId: r.column("inventory_id")?.int ?? 0,
            customerId: r.column("customer_id")?.int ?? 0,
            staffId: r.column("staff_id")?.int ?? 0,
            customerName: r.column("customer_name")?.string,
            filmTitle: r.column("film_title")?.string,
            staffName: r.column("staff_name")?.string
        )
    }
}

enum DatabaseError: LocalizedError {
    case notConnected
    case notFound
    case insertFailed

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to database. Please configure connection in Settings."
        case .notFound: return "Record not found."
        case .insertFailed: return "Failed to insert record."
        }
    }
}
