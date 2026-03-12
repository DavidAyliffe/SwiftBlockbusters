// DatabaseService.swift
// Centralized database access layer for the Blockbusters application.
// Manages the MySQL connection lifecycle and provides async query methods
// for films, customers, staff, rentals, and dashboard statistics.
// Uses MySQLNIO (Vapor's async MySQL driver) over SwiftNIO event loops.

import Foundation
import MySQLNIO
import NIOPosix
import Logging

/// Singleton service responsible for all MySQL database interactions.
/// Marked as `@Observable` so SwiftUI views can react to connection state changes.
/// Marked as `Sendable` to allow safe usage across concurrency domains.
@Observable
final class DatabaseService: Sendable {
    /// Shared singleton instance used throughout the application
    static let shared = DatabaseService()

    // MARK: - Connection State
    // These properties are MainActor-isolated so they can be safely bound to SwiftUI views.

    /// Whether a database connection is currently established
    @MainActor var isConnected = false
    /// Human-readable error message if the last connection attempt failed
    @MainActor var connectionError: String?

    // MARK: - Connection Configuration
    // Default values for the MySQL connection — editable from the Settings view.

    /// MySQL server hostname or IP address
    @MainActor var host = "127.0.0.1"
    /// MySQL server port number
    @MainActor var port = 3306
    /// MySQL username for authentication
    @MainActor var username = "root"
    /// MySQL password for authentication
    @MainActor var password = "rootroot"
    /// Name of the MySQL database/schema to connect to
    @MainActor var database = "blockbusters"

    /// NIO event loop group used for non-blocking I/O with the MySQL connection
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    /// The active MySQL connection (nil when disconnected).
    /// Marked `nonisolated(unsafe)` because it is accessed from multiple isolation domains
    /// but is only mutated under controlled conditions (connect/disconnect).
    private nonisolated(unsafe) var _connection: MySQLConnection?

    /// Private initializer enforces singleton usage via `DatabaseService.shared`.
    private init() {}

    // MARK: - Connection Management

    /// Establishes a connection to the MySQL database using the current configuration.
    /// Captures config values from MainActor properties before performing the async connect.
    @MainActor
    func connect() async {
        connectionError = nil
        // Capture MainActor-isolated config values into local constants
        // so they can be used off the main actor in the connection call.
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

    /// Creates a new MySQLConnection using the provided credentials.
    /// - Parameters:
    ///   - host: MySQL server hostname
    ///   - port: MySQL server port
    ///   - username: Authentication username
    ///   - password: Authentication password
    ///   - database: Database schema name
    /// - Returns: An active `MySQLConnection`
    private func connectToMySQL(host: String, port: Int, username: String, password: String, database: String) async throws -> MySQLConnection {
        // Configure a logger with minimal output to avoid noisy connection logs
        var logger = Logger(label: "sakila-app")
        logger.logLevel = .warning

        // Get the next available event loop from the group for this connection
        let eventLoop = eventLoopGroup.next()
        // Establish the MySQL connection (TLS disabled for local development)
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

    /// Closes the current database connection and resets the connection state.
    @MainActor
    func disconnect() async {
        guard let conn = _connection else { return }
        _connection = nil
        // Attempt to gracefully close the connection; ignore errors on disconnect
        try? await conn.close().get()
        isConnected = false
    }

    /// Returns the active connection or throws an error if not connected.
    /// Used internally by all query methods to ensure a connection exists before querying.
    /// - Throws: `DatabaseError.notConnected` if no active connection
    private func requireConnection() throws -> MySQLConnection {
        guard let conn = _connection else {
            throw DatabaseError.notConnected
        }
        return conn
    }

    // MARK: - Film Queries

    /// Fetches a filtered list of films from the database.
    /// Supports searching by title, filtering by category, and filtering by MPAA rating.
    /// Results are ordered alphabetically by title and limited to 500 rows.
    /// - Parameters:
    ///   - search: Title search string (uses SQL LIKE with wildcards)
    ///   - category: Optional category name to filter by (exact match)
    ///   - rating: Optional MPAA rating to filter by (exact match)
    /// - Returns: An array of `Film` objects matching the criteria
    func fetchFilms(search: String = "", category: String? = nil, rating: String? = nil) async throws -> [Film] {
        let conn = try requireConnection()

        // Build the base SELECT query for film data
        var sql = """
            SELECT DISTINCT f.film_id, f.title, f.description, f.release_year,
                   f.language_id, f.rental_duration, f.rental_rate, f.length,
                   f.replacement_cost, f.rating, f.special_features
            FROM film f
            """

        var binds: [MySQLData] = []
        var conditions: [String] = []

        // If filtering by category, join through the film_category and category tables
        if category != nil {
            sql += """
                 JOIN film_category fc ON f.film_id = fc.film_id
                 JOIN category c ON fc.category_id = c.category_id
                """
        }

        // Add title search condition with wildcard matching
        if !search.isEmpty {
            conditions.append("f.title LIKE ?")
            binds.append(.init(string: "%\(search)%"))
        }

        // Add category filter condition
        if let category, !category.isEmpty {
            conditions.append("c.name = ?")
            binds.append(.init(string: category))
        }

        // Add rating filter condition
        if let rating, !rating.isEmpty {
            conditions.append("f.rating = ?")
            binds.append(.init(string: rating))
        }

        // Combine all WHERE conditions with AND
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }

        // Order alphabetically and cap results to avoid loading the entire catalogue at once
        sql += " ORDER BY f.title LIMIT 500"

        // Execute the query and map each row to a Film model
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

    /// Fetches comprehensive detail for a single film, including actors, categories, and inventory.
    /// - Parameter filmId: The film_id to look up
    /// - Returns: A `FilmDetail` containing the film, its cast, genres, and inventory breakdown
    /// - Throws: `DatabaseError.notFound` if no film exists with the given ID
    func fetchFilmDetail(filmId: Int) async throws -> FilmDetail {
        let conn = try requireConnection()

        // Fetch the film's core data
        let filmRows = try await conn.query(
            "SELECT * FROM film WHERE film_id = ?",
            [.init(int: filmId)]
        ).get()

        guard let row = filmRows.first else {
            throw DatabaseError.notFound
        }

        // Map the row to a Film model
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

        // Fetch actors associated with this film via the film_actor join table
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

        // Fetch categories/genres via the film_category join table
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

        // Fetch inventory counts grouped by store, including availability
        // A copy is "available" if it has no active (unreturned) rental
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

    /// Fetches all film categories ordered alphabetically by name.
    /// Used to populate category filter dropdowns.
    /// - Returns: An array of `Category` objects
    func fetchCategories() async throws -> [Category] {
        let conn = try requireConnection()
        let rows = try await conn.query("SELECT category_id, name FROM category ORDER BY name").get()
        return rows.map { r in
            Category(id: r.column("category_id")?.int ?? 0, name: r.column("name")?.string ?? "")
        }
    }

    // MARK: - Customer Queries

    /// Fetches customers with optional search filtering.
    /// Joins the address and city tables to include location information.
    /// Searches across first name, last name, and email fields.
    /// - Parameter search: Optional search string to filter customers
    /// - Returns: An array of `Customer` objects with address info populated
    func fetchCustomers(search: String = "") async throws -> [Customer] {
        let conn = try requireConnection()

        // Base query joins address and city tables for complete customer info
        var sql = """
            SELECT c.customer_id, c.store_id, c.first_name, c.last_name, c.email,
                   c.address_id, c.active,
                   a.address, a.district, ci.name, a.postal_code, a.phone
            FROM customer c
            JOIN address a ON c.address_id = a.address_id
            JOIN city ci ON a.city_id = ci.city_id
            """
        var binds: [MySQLData] = []

        // If a search term is provided, filter across name and email fields
        if !search.isEmpty {
            sql += " WHERE c.first_name LIKE ? OR c.last_name LIKE ? OR c.email LIKE ?"
            let pattern = MySQLData(string: "%\(search)%")
            binds = [pattern, pattern, pattern]
        }

        sql += " ORDER BY c.last_name, c.first_name LIMIT 500"

        // Execute and map rows to Customer models
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

    /// Adds a new customer with a new address record.
    /// First inserts the address, retrieves its auto-generated ID, then inserts the customer.
    /// - Parameters:
    ///   - firstName: Customer's first name
    ///   - lastName: Customer's last name
    ///   - email: Customer's email address
    ///   - storeId: Store the customer is registered at
    ///   - address: Street address
    ///   - district: District or region
    ///   - cityId: Foreign key to the city table
    ///   - postalCode: Postal/ZIP code
    ///   - phone: Phone number
    func addCustomer(firstName: String, lastName: String, email: String, storeId: Int, address: String, district: String, cityId: Int, postalCode: String, phone: String) async throws {
        let conn = try requireConnection()

        // Step 1: Insert the address record first (customer references it via FK).
        // The `location` column requires a spatial value — we use a default POINT(0 0).
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

        // Step 2: Retrieve the auto-incremented address ID from the insert
        let addrRows = try await conn.query("SELECT LAST_INSERT_ID() as id").get()
        guard let addressId = addrRows.first?.column("id")?.int else {
            throw DatabaseError.insertFailed
        }

        // Step 3: Insert the customer record referencing the new address
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

    /// Updates an existing customer's personal information.
    /// Does not update address fields — only core customer table columns.
    /// - Parameters:
    ///   - id: The customer_id to update
    ///   - firstName: Updated first name
    ///   - lastName: Updated last name
    ///   - email: Updated email address
    ///   - storeId: Updated store assignment
    ///   - active: Updated active status
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

    /// Deletes a customer and all their associated records.
    /// Removes payments and rentals first to satisfy foreign key constraints,
    /// then deletes the customer record itself.
    /// - Parameter id: The customer_id to delete
    func deleteCustomer(id: Int) async throws {
        let conn = try requireConnection()
        // Delete in order: payments → rentals → customer (respecting FK constraints)
        _ = try await conn.query("DELETE FROM payment WHERE customer_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM rental WHERE customer_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM customer WHERE customer_id = ?", [.init(int: id)]).get()
    }

    // MARK: - Staff Queries

    /// Fetches all staff members with their address and city information.
    /// Joins the address and city tables for complete staff contact details.
    /// - Returns: An array of `Staff` objects ordered by last name, first name
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

    /// Adds a new staff member to the database.
    /// Requires an existing address_id (unlike addCustomer which creates a new address).
    /// - Parameters:
    ///   - firstName: Staff member's first name
    ///   - lastName: Staff member's last name
    ///   - email: Staff member's email address
    ///   - storeId: Store assignment
    ///   - username: Login username
    ///   - addressId: Foreign key to an existing address record
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

    /// Updates an existing staff member's information.
    /// - Parameters:
    ///   - id: The staff_id to update
    ///   - firstName: Updated first name
    ///   - lastName: Updated last name
    ///   - email: Updated email address
    ///   - storeId: Updated store assignment
    ///   - username: Updated login username
    ///   - active: Updated active/employment status
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

    /// Deletes a staff member and all their associated payment/rental records.
    /// Removes payments and rentals first to satisfy foreign key constraints.
    /// - Parameter id: The staff_id to delete
    func deleteStaff(id: Int) async throws {
        let conn = try requireConnection()
        // Delete in order: payments → rentals → staff (respecting FK constraints)
        _ = try await conn.query("DELETE FROM payment WHERE staff_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM rental WHERE staff_id = ?", [.init(int: id)]).get()
        _ = try await conn.query("DELETE FROM staff WHERE staff_id = ?", [.init(int: id)]).get()
    }

    // MARK: - Rental Queries

    /// Fetches all currently active (unreturned) rentals.
    /// Joins customer, inventory, film, and staff tables for display-friendly data.
    /// - Returns: An array of active `Rental` objects ordered by rental date descending
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

    /// Fetches the most recent rental transactions (both active and returned).
    /// Used on the dashboard to show recent activity.
    /// - Parameter limit: Maximum number of rentals to return (default: 10)
    /// - Returns: An array of `Rental` objects ordered by rental date descending
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

    /// Creates a new rental transaction and its associated payment record.
    /// Steps: insert rental → get rental ID → look up film rental rate → insert payment.
    /// - Parameters:
    ///   - inventoryId: The specific inventory copy being rented
    ///   - customerId: The customer renting the film
    ///   - staffId: The staff member processing the rental
    func createRental(inventoryId: Int, customerId: Int, staffId: Int) async throws {
        let conn = try requireConnection()

        // Step 1: Insert the rental record with the current timestamp
        _ = try await conn.query("""
            INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
            VALUES (NOW(), ?, ?, ?)
            """, [
                .init(int: inventoryId),
                .init(int: customerId),
                .init(int: staffId)
            ]).get()

        // Step 2: Retrieve the auto-generated rental ID
        let rentalRows = try await conn.query("SELECT LAST_INSERT_ID() as id").get()
        guard let rentalId = rentalRows.first?.column("id")?.int else { return }

        // Step 3: Look up the rental rate for the film associated with this inventory copy
        let rateRows = try await conn.query("""
            SELECT f.rental_rate FROM film f
            JOIN inventory i ON f.film_id = i.film_id
            WHERE i.inventory_id = ?
            """, [.init(int: inventoryId)]).get()
        let rate = rateRows.first?.column("rental_rate")?.string ?? "4.99"

        // Step 4: Insert a corresponding payment record for the rental
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

    /// Processes a film return by setting the returned_date to the current timestamp.
    /// - Parameter rentalId: The rental_id to mark as returned
    func processReturn(rentalId: Int) async throws {
        let conn = try requireConnection()
        _ = try await conn.query("""
            UPDATE rental SET returned_date = NOW() WHERE rental_id = ?
            """, [.init(int: rentalId)]).get()
    }

    /// Fetches all inventory items for a given film, showing availability status.
    /// A copy is considered available if it has no active (unreturned) rental.
    /// - Parameter filmId: The film_id to look up inventory for
    /// - Returns: An array of `InventoryItem` objects ordered by store and inventory ID
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

    /// Fetches aggregated statistics for the dashboard overview.
    /// Runs multiple COUNT/SUM queries to gather metrics, then fetches
    /// top-rented films and recent rental activity.
    /// - Returns: A fully populated `DashboardStats` object
    func fetchDashboardStats() async throws -> DashboardStats {
        let conn = try requireConnection()

        // Gather aggregate counts from various tables
        let filmCount = try await conn.query("SELECT COUNT(*) as cnt FROM film").get()
        let custCount = try await conn.query("SELECT COUNT(*) as cnt FROM customer").get()
        let staffCount = try await conn.query("SELECT COUNT(*) as cnt FROM staff").get()
        let activeRentals = try await conn.query("SELECT COUNT(*) as cnt FROM rental WHERE returned_date IS NULL").get()

        // Count overdue rentals: those past the film's rental_duration with no return date
        let overdueRentals = try await conn.query("""
            SELECT COUNT(*) as cnt FROM rental r
            JOIN film f ON r.inventory_id = f.film_id
            WHERE r.returned_date IS NULL
            AND DATE_ADD(r.rental_date, INTERVAL f.rental_duration DAY) < NOW()
            """).get()

        // Sum all payment amounts for total revenue
        let revenue = try await conn.query("SELECT COALESCE(SUM(amount), 0) as total FROM payment").get()

        // Fetch the top 5 most-rented films by rental count
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

        // Fetch the 10 most recent rentals for the activity feed
        let recentRentals = try await fetchRecentRentals(limit: 10)

        // Assemble all stats into the dashboard model
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

    /// Fetches all cities from the database for use in address form dropdowns.
    /// Limited to 600 entries for performance.
    /// - Returns: An array of (id, name) tuples ordered alphabetically
    func fetchCities() async throws -> [(id: Int, name: String)] {
        let conn = try requireConnection()
        let rows = try await conn.query("SELECT city_id, city FROM city ORDER BY city LIMIT 600").get()
        return rows.map { r in
            (id: r.column("city_id")?.int ?? 0, name: r.column("city")?.string ?? "")
        }
    }

    // MARK: - Helpers

    /// Parses a MySQL row from a rental query into a `Rental` model.
    /// Handles date parsing from MySQL's "yyyy-MM-dd HH:mm:ss" format.
    /// - Parameter r: A `MySQLRow` containing rental data with joined display fields
    /// - Returns: A populated `Rental` instance
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

/// Custom error types for database operations.
/// Provides user-friendly error descriptions for common failure scenarios.
enum DatabaseError: LocalizedError {
    /// No active database connection — user needs to configure settings
    case notConnected
    /// A queried record was not found in the database
    case notFound
    /// An INSERT operation failed (e.g., could not retrieve LAST_INSERT_ID)
    case insertFailed

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to database. Please configure connection in Settings."
        case .notFound: return "Record not found."
        case .insertFailed: return "Failed to insert record."
        }
    }
}
