# 🎬 Swift Blockbusters Manager

A native macOS desktop app built with SwiftUI that connects directly to a local MySQL [Sakila](https://dev.mysql.com/doc/sakila/en/) database. Browse your film catalogue, manage customers and staff, process rentals and returns, and monitor store statistics — all from a clean, sidebar-driven Mac interface.

---

## ✨ Features

### 📊 Dashboard
- At-a-glance overview cards: total films, customers, staff, active rentals, overdue count, and revenue
- Top 5 most-rented films
- Recent rentals feed

### 🎥 Films
- Searchable, filterable film catalogue (filter by category and/or MPAA rating)
- Detail view with description, full cast, categories, rental/replacement cost, and per-store inventory levels

### 👥 Customers
- Browse and search the full customer list
- Add, edit, and delete customers with a guided form

### 🧑‍💼 Staff
- View all staff members across stores
- Add, edit, and delete staff records

### 📼 Rentals
- View all active rentals and flag overdue items
- Process returns in one click
- Create new rentals with a step-by-step customer → film → inventory selection flow

### ⚙️ Settings
- Persistent database connection configuration (host, port, username, password, database name)
- Connect / disconnect controls with live status indicator

---

## 🖥️ Requirements

| Requirement | Version |
|---|---|
| macOS | 14 Sonoma or later |
| Xcode | 15 or later |
| MySQL | 8.0+ with the Sakila sample database |

> 📥 **Sakila database**: [https://dev.mysql.com/doc/sakila/en/](https://dev.mysql.com/doc/sakila/en/)

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/DavidAyliffe/SakilaApp.git
cd SakilaApp
```

### 2. Open in Xcode

```bash
open SakilaApp/
```

Or open the folder directly in Xcode via **File → Open…**

### 3. Build and run

Press **⌘R** (or **Product → Run**) to build and launch the app.

### 4. Configure your database connection

On first launch, click the 🔌 connection icon in the toolbar or go to **Settings** and enter:

| Field | Default value |
|---|---|
| Host | `127.0.0.1` |
| Port | `3306` |
| Username | `root` |
| Password | *(your MySQL root password)* |
| Database | `sakila` |

Click **Connect** — the status indicator will turn green when the connection is established.

---

## 🏗️ Architecture

| Layer | Technology |
|---|---|
| **UI** | SwiftUI — `NavigationSplitView` sidebar layout |
| **Pattern** | MVVM (`@Observable` view models) |
| **Database driver** | [mysql-nio](https://github.com/vapor/mysql-nio) — Vapor's pure-Swift async MySQL driver |
| **Package manager** | Swift Package Manager |
| **Concurrency** | Swift structured concurrency (`async`/`await`) |

---

## 📁 Project Structure

```
Sources/SakilaApp/
│
├── SakilaApp.swift                  # 🚀 App entry point & window configuration
│
├── Models/                          # 📦 Identifiable value types (Sakila schema)
│   ├── Actor.swift
│   ├── Category.swift
│   ├── Customer.swift
│   ├── DashboardStats.swift
│   ├── Film.swift
│   ├── Rental.swift
│   └── Staff.swift
│
├── Services/
│   └── DatabaseService.swift        # 🗄️ MySQL connection pool & all query methods
│
├── ViewModels/                      # 🧠 @Observable state & business logic
│   ├── CustomerViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── FilmViewModel.swift
│   ├── RentalViewModel.swift
│   └── StaffViewModel.swift
│
└── Views/
    ├── ContentView.swift            # 🗂️ Root sidebar navigation
    ├── SettingsView.swift           # ⚙️ DB connection settings
    ├── DashboardView.swift          # 📊 Stats dashboard
    ├── Films/
    │   ├── FilmListView.swift       # 🎥 Searchable film catalogue
    │   └── FilmDetailView.swift     # 🎞️ Film detail & inventory
    ├── Customers/
    │   ├── CustomerListView.swift   # 👥 Customer browser
    │   └── CustomerFormView.swift   # ✏️ Add / edit customer
    ├── Staff/
    │   ├── StaffListView.swift      # 🧑‍💼 Staff browser
    │   └── StaffFormView.swift      # ✏️ Add / edit staff
    └── Rentals/
        └── RentalView.swift         # 📼 Rental management
```

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.
