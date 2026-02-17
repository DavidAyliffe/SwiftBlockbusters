import SwiftUI

struct FilmListView: View {
    @State private var viewModel = FilmViewModel()
    @State private var selectedFilm: Film?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filters
                HStack {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(String?.none)
                        ForEach(viewModel.categories) { cat in
                            Text(cat.name).tag(Optional(cat.name))
                        }
                    }
                    .frame(maxWidth: 160)

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

                List(viewModel.films, selection: $selectedFilm) { film in
                    FilmRow(film: film)
                        .tag(film)
                }
            }
            .navigationTitle("Films")
            .searchable(text: $viewModel.searchText, prompt: "Search films...")
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
            if let film = selectedFilm {
                FilmDetailView(filmId: film.id)
            } else {
                Text("Select a film")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.films.isEmpty {
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
            await viewModel.loadCategories()
            await viewModel.loadFilms()
        }
    }
}

struct FilmRow: View {
    let film: Film

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(film.title)
                .font(.headline)
            HStack {
                Text(film.formattedRating)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())

                if let year = film.releaseYear {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(film.formattedLength)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("$\(film.rentalRate)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}
