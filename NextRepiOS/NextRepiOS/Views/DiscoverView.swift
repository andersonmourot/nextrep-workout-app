import SwiftUI

@Observable
class DiscoverViewModel {
    var users: [DiscoverUser] = []
    var isLoading = false
    var errorMessage = ""
    var searchQuery = ""
    
    func performSearch() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let results: [DiscoverUser] = try await APIClient.shared.searchUsers(query: searchQuery)
            await MainActor.run {
                self.users = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func followUser(_ user: DiscoverUser) async {
        do {
            try await APIClient.shared.followUser(user.id)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func unfollowUser(_ user: DiscoverUser) async {
        do {
            try await APIClient.shared.unfollowUser(user.id)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search users...", text: $viewModel.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await viewModel.performSearch()
                            }
                        }
                    
                    Button("Search") {
                        Task {
                            await viewModel.performSearch()
                        }
                    }
                    .disabled(viewModel.searchQuery.isEmpty)
                }
                .padding()
                
                // Content
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.errorMessage.isEmpty {
                    VStack {
                        Text("Error: \(viewModel.errorMessage)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.performSearch()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.users.isEmpty {
                    ContentUnavailableView("No Users Found", systemImage: "person.3")
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRow(user: user, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserRow: View {
    let user: DiscoverUser
    @Bindable var viewModel: DiscoverViewModel
    @State private var isFollowing = false
    
    var body: some View {
        HStack {
            // User avatar placeholder
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(user.sharedProgramCount) programs", systemImage: "dumbbell")
                    Label("\(user.sharedExerciseCount) exercises", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    if user.following {
                        await viewModel.unfollowUser(user)
                    } else {
                        await viewModel.followUser(user)
                    }
                }
            }) {
                Text(user.following ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(user.following ? Color.green.opacity(0.2) : Color.green)
                    .foregroundColor(.green)
                    .cornerRadius(15)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DiscoverView()
}