// DashboardView.swift
// The main dashboard screen displaying key business metrics at a glance.
// Shows stat cards (films, customers, staff, rentals, revenue),
// a top 5 rented films leaderboard, and a recent rentals activity feed.

import SwiftUI

/// Dashboard view that presents an overview of the rental business.
/// Loads statistics on appear and provides a manual refresh button.
struct DashboardView: View {
    /// ViewModel managing the dashboard data and loading state
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Statistics Cards Grid
                // 3-column grid displaying key business metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Total Films", value: "\(viewModel.stats.totalFilms)", icon: "film", color: .blue)
                    StatCard(title: "Customers", value: "\(viewModel.stats.totalCustomers)", icon: "person.2.fill", color: .green)
                    StatCard(title: "Staff", value: "\(viewModel.stats.totalStaff)", icon: "person.badge.key.fill", color: .purple)
                    StatCard(title: "Active Rentals", value: "\(viewModel.stats.activeRentals)", icon: "arrow.triangle.2.circlepath", color: .orange)
                    StatCard(title: "Overdue", value: "\(viewModel.stats.overdueRentals)", icon: "exclamationmark.triangle.fill", color: .red)
                    StatCard(title: "Total Revenue", value: "$\(viewModel.stats.totalRevenue)", icon: "dollarsign.circle.fill", color: .mint)
                }

                // MARK: - Detail Panels (Top Films & Recent Rentals)
                HStack(alignment: .top, spacing: 20) {
                    // Top 5 most-rented films leaderboard
                    GroupBox("Top 5 Rented Films") {
                        if viewModel.stats.topFilms.isEmpty {
                            Text("No data")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                // Display each film with its rank number and rental count
                                ForEach(Array(viewModel.stats.topFilms.enumerated()), id: \.element.id) { index, film in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24, alignment: .trailing)
                                        Text(film.title)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(film.rentalCount) rentals")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }
                                    // Add dividers between items (but not after the last one)
                                    if index < viewModel.stats.topFilms.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Recent rental activity feed
                    GroupBox("Recent Rentals") {
                        if viewModel.stats.recentRentals.isEmpty {
                            Text("No data")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.stats.recentRentals) { rental in
                                    HStack {
                                        // Film title and customer name
                                        VStack(alignment: .leading) {
                                            Text(rental.filmTitle ?? "Unknown")
                                                .lineLimit(1)
                                            Text(rental.customerName ?? "Unknown")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        // Rental date and active status badge
                                        VStack(alignment: .trailing) {
                                            Text(rental.rentalDate, style: .date)
                                                .font(.caption)
                                            if rental.isActive {
                                                Text("Active")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.orange.opacity(0.2))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    // Add dividers between items
                                    if rental.id != viewModel.stats.recentRentals.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .toolbar {
            // Manual refresh button
            ToolbarItem {
                Button {
                    Task { await viewModel.loadStats() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        // Loading spinner overlay
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        // Error alert dialog
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // Load stats when the view first appears
        .task {
            await viewModel.loadStats()
        }
    }
}

/// A reusable card component that displays a single statistic with an icon.
/// Used in the dashboard grid to show metrics like total films, revenue, etc.
struct StatCard: View {
    /// Label displayed below the value (e.g., "Total Films")
    let title: String
    /// The metric value to display prominently (e.g., "1000")
    let value: String
    /// SF Symbol name for the card's icon
    let icon: String
    /// Accent color for the icon
    let color: Color

    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
