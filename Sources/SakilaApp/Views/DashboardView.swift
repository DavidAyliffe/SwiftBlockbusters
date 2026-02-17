import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stats cards
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

                HStack(alignment: .top, spacing: 20) {
                    // Top rented films
                    GroupBox("Top 5 Rented Films") {
                        if viewModel.stats.topFilms.isEmpty {
                            Text("No data")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
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
                                    if index < viewModel.stats.topFilms.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Recent rentals
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
                                        VStack(alignment: .leading) {
                                            Text(rental.filmTitle ?? "Unknown")
                                                .lineLimit(1)
                                            Text(rental.customerName ?? "Unknown")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
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
            ToolbarItem {
                Button {
                    Task { await viewModel.loadStats() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadStats()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
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
