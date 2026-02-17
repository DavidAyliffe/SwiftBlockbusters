import SwiftUI

struct FilmDetailView: View {
    let filmId: Int
    @State private var viewModel = FilmViewModel()

    private var detail: FilmDetail? { viewModel.selectedFilmDetail }

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
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

                        if let description = detail.film.description {
                            GroupBox("Description") {
                                Text(description)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        HStack(alignment: .top, spacing: 20) {
                            // Details
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

                            // Categories
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

                        // Actors
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

                        // Inventory
                        GroupBox("Inventory by Store") {
                            if detail.inventoryByStore.isEmpty {
                                Text("No inventory")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(detail.inventoryByStore) { inv in
                                    HStack {
                                        Label("Store \(inv.storeId)", systemImage: "building.2")
                                        Spacer()
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
                Text(viewModel.errorMessage ?? "Error loading film")
                    .foregroundStyle(.red)
            } else {
                ProgressView()
            }
        }
        .task(id: filmId) {
            await viewModel.loadFilmDetail(filmId: filmId)
        }
    }
}

struct DetailRow: View {
    let label: String
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

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
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
