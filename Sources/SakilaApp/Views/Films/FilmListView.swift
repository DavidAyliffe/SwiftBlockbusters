// FilmListView.swift
// The main film browsing view with search, category/rating filters, and a detail pane.
// Uses a nested NavigationSplitView to show a film list on the left and film detail on the right.

import SwiftUI

/// Film list view with search, category and rating filters, and an embedded detail pane.
/// Films can be selected to view their full detail in the right panel.
struct FilmListView: View {
    /// ViewModel managing film data, filters, and loading state
    @State private var viewModel = FilmViewModel()
    /// The currently selected film (drives the detail pane)
    @State private var selectedFilm: Film?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // MARK: - Filter Controls
                // Category and rating dropdown filters above the film list
                HStack {
                    // Category filter: "All Categories" plus dynamic categories from DB
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(String?.none)
                        ForEach(viewModel.categories) { cat in
                            Text(cat.name).tag(Optional(cat.name))
                        }
                    }
                    .frame(maxWidth: 160)

                    // Rating filter: "All Ratings" plus the standard MPAA ratings
                    Picker("Rating", selection: $viewModel.selectedRating) {
                        Text("All Ratings").tag(String?.none)
                        ForEach(FilmViewModel.ratings, id: \.self) { rating in
                            Text(rating).tag(Optional(rating))
                        }
                    }
                    .frame(maxWidth: 120)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // MARK: - Film List
                // Selectable list of films; selecting a film shows its detail
                List(viewModel.films, selection: $selectedFilm) { film in
                    FilmRow(film: film)
                        .tag(film)
                }
            }
            .navigationTitle("Films")
            // Search bar for title-based filtering
            .searchable(text: $viewModel.searchText, prompt: "Search films...")
            // Reload films when any filter changes
            .onChange(of: viewModel.searchText) { _, _ in
                Task { await viewModel.loadFilms() }
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                Task { await viewModel.loadFilms() }
            }
            .onChange(of: viewModel.selectedRating) { _, _ in
                Task { await viewModel.loadFilms() }
            }
            .toolbar {
                // Manual refresh button
                ToolbarItem {
                    Button {
                        Task { await viewModel.loadFilms() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        } detail: {
            // Detail pane: shows full film info when a film is selected
            if let film = selectedFilm {
                FilmDetailView(filmId: film.id)
            } else {
                Text("Select a film")
                    .foregroundStyle(.secondary)
            }
        }
        // Loading spinner for initial load
        .overlay {
            if viewModel.isLoading && viewModel.films.isEmpty {
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
        // Load categories and films when the view first appears
        .task {
            await viewModel.loadCategories()
            await viewModel.loadFilms()
        }
    }
}

/// A row component displaying a film's key information in the film list.
/// Shows the title, MPAA rating badge, release year, duration, and rental price.
struct FilmRow: View {
    /// The film data to display
    let film: Film

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(film.title)
                .font(.headline)
            HStack {
                // MPAA rating displayed as a blue capsule badge
                Text(film.formattedRating)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())

                // Release year (if available)
                if let year = film.releaseYear {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Film duration in human-readable format
                Text(film.formattedLength)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Rental price in green
                Text("$\(film.rentalRate)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}
