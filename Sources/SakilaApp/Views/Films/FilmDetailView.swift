// FilmDetailView.swift
// Displays comprehensive detail for a single film, including metadata,
// description, cast, categories, and per-store inventory availability.
// Also includes reusable helper views: DetailRow and FlowLayout.

import SwiftUI

/// Detail view for a single film, loaded by film ID.
/// Shows the film's title, metadata, description, cast, categories, and inventory.
struct FilmDetailView: View {
    /// The film_id to load detail for (passed from the film list)
    let filmId: Int
    /// ViewModel used to fetch the film detail data
    @State private var viewModel = FilmViewModel()

    /// Convenience accessor for the loaded film detail
    private var detail: FilmDetail? { viewModel.selectedFilmDetail }

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Header Section
                        // Film title and key metadata (year, rating, duration, rental rate)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(detail.film.title)
                                .font(.largeTitle.bold())

                            HStack(spacing: 12) {
                                if let year = detail.film.releaseYear {
                                    Label(String(year), systemImage: "calendar")
                                }
                                Label(detail.film.formattedRating, systemImage: "star.fill")
                                Label(detail.film.formattedLength, systemImage: "clock")
                                Label("$\(detail.film.rentalRate)/rental", systemImage: "dollarsign.circle")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        // MARK: - Description Section
                        if let description = detail.film.description {
                            GroupBox("Description") {
                                Text(description)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // MARK: - Details & Categories Side-by-Side
                        HStack(alignment: .top, spacing: 20) {
                            // Film rental/replacement details
                            GroupBox("Details") {
                                VStack(alignment: .leading, spacing: 6) {
                                    DetailRow(label: "Rental Duration", value: "\(detail.film.rentalDuration) days")
                                    DetailRow(label: "Replacement Cost", value: "$\(detail.film.replacementCost)")
                                    if let features = detail.film.specialFeatures {
                                        DetailRow(label: "Special Features", value: features)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)

                            // Genre/category tags displayed as capsule badges
                            GroupBox("Categories") {
                                if detail.categories.isEmpty {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                } else {
                                    FlowLayout(spacing: 6) {
                                        ForEach(detail.categories) { cat in
                                            Text(cat.name)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.blue.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // MARK: - Cast Section
                        // Actors displayed as capsule tags in a flow layout
                        GroupBox("Cast (\(detail.actors.count))") {
                            if detail.actors.isEmpty {
                                Text("No actors listed")
                                    .foregroundStyle(.secondary)
                            } else {
                                FlowLayout(spacing: 6) {
                                    ForEach(detail.actors) { actor in
                                        Text(actor.fullName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.gray.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // MARK: - Inventory Section
                        // Per-store inventory with available/total counts
                        GroupBox("Inventory by Store") {
                            if detail.inventoryByStore.isEmpty {
                                Text("No inventory")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(detail.inventoryByStore) { inv in
                                    HStack {
                                        Label("Store \(inv.storeId)", systemImage: "building.2")
                                        Spacer()
                                        // Green if copies available, red if all rented out
                                        Text("\(inv.availableCount) available / \(inv.totalCount) total")
                                            .foregroundStyle(inv.availableCount > 0 ? .green : .red)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else if viewModel.errorMessage != nil {
                // Error state
                Text(viewModel.errorMessage ?? "Error loading film")
                    .foregroundStyle(.red)
            } else {
                // Loading state
                ProgressView()
            }
        }
        // Reload detail whenever the filmId changes (e.g., selecting a different film)
        .task(id: filmId) {
            await viewModel.loadFilmDetail(filmId: filmId)
        }
    }
}

/// A horizontal label-value row used in the film detail "Details" section.
/// Shows a label on the left and its corresponding value on the right.
struct DetailRow: View {
    /// The label text (e.g., "Rental Duration")
    let label: String
    /// The value text (e.g., "3 days")
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
        }
        .font(.callout)
    }
}

/// A custom layout that arranges subviews in a horizontal flow, wrapping to the next line
/// when a subview would exceed the available width. Used for displaying tag/capsule collections.
struct FlowLayout: Layout {
    /// Spacing between items both horizontally and vertically
    let spacing: CGFloat

    /// Calculates the total size needed to render all subviews in a flow layout.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    /// Places each subview at its calculated position within the flow layout.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    /// Core layout algorithm that calculates positions for all subviews.
    /// Iterates through subviews left-to-right, wrapping to a new row when
    /// the next item would exceed the available width.
    /// - Returns: A tuple of the total content size and an array of positions for each subview
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0        // Current horizontal position
        var y: CGFloat = 0        // Current vertical position (top of current row)
        var rowHeight: CGFloat = 0 // Tallest item in the current row
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Wrap to next line if this item would exceed the available width
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
