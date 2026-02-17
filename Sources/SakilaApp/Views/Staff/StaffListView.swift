import SwiftUI

struct StaffListView: View {
    @State private var viewModel = StaffViewModel()

    var body: some View {
        List {
            ForEach(viewModel.staffMembers) { staff in
                StaffRow(staff: staff)
                    .contextMenu {
                        Button("Edit") {
                            viewModel.beginEdit(staff)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteStaff(id: staff.id) }
                        }
                    }
            }
        }
        .navigationTitle("Staff (\(viewModel.staffMembers.count))")
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.beginAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Staff")
            }
            ToolbarItem {
                Button {
                    Task { await viewModel.loadStaff() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.staffMembers.isEmpty {
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
        .sheet(isPresented: $viewModel.showingForm) {
            StaffFormView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadStaff()
        }
    }
}

struct StaffRow: View {
    let staff: Staff

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(staff.fullName)
                        .font(.headline)
                    if !staff.active {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 8) {
                    Text("@\(staff.username)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    if let email = staff.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Store \(staff.storeId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let city = staff.city {
                    Text(city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
