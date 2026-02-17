# Sakila Manager

A macOS desktop app built with SwiftUI that connects to a local MySQL Sakila database for browsing films, managing customers and staff, processing rentals, and viewing dashboard statistics.

## Requirements

- macOS 14+
- Xcode 15+
- MySQL server with the [Sakila sample database](https://dev.mysql.com/doc/sakila/en/) installed

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/DavidAyliffe/SakilaApp.git
   ```

2. Open in Xcode:
   ```bash
   open SakilaApp/
   ```

3. Build and run (Cmd+R)

4. Configure your database connection via the toolbar connection icon or the Settings menu:
   - Host: `127.0.0.1`
   - Port: `3306`
   - Username: `root`
   - Password: *(your password)*
   - Database: `sakila`

## Features

- **Dashboard** — Overview cards (total films, customers, staff, active rentals, overdue count, revenue) with top 5 rented films and recent rentals
- **Films** — Searchable and filterable list by category and rating, with detail view showing description, cast, categories, and per-store inventory
- **Customers** — Browse, search, add, edit, and delete customers
- **Staff** — Browse, add, edit, and delete staff members
- **Rentals** — View active rentals, process returns, and create new rentals with a guided customer/film/inventory selection flow

## Architecture

- **Platform**: macOS 14+ SwiftUI (NavigationSplitView sidebar layout)
- **Pattern**: MVVM
- **MySQL Driver**: [mysql-nio](https://github.com/vapor/mysql-nio) (Vapor's pure-Swift async MySQL driver)
- **Package Manager**: Swift Package Manager

## Project Structure

```
Sources/SakilaApp/
├── SakilaApp.swift              # App entry point
├── Models/                      # Identifiable structs matching Sakila schema
├── Services/
│   └── DatabaseService.swift    # MySQL connection and all queries
├── ViewModels/                  # @Observable classes per feature area
└── Views/
    ├── ContentView.swift        # Sidebar navigation
    ├── SettingsView.swift       # DB connection config
    ├── DashboardView.swift      # Stats and lists
    ├── Films/                   # Film list and detail
    ├── Customers/               # Customer list and form
    ├── Staff/                   # Staff list and form
    └── Rentals/                 # Rental management
```

## License

MIT
