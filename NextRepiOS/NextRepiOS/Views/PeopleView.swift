import SwiftUI

struct PeopleView: View {
    @StateObject private var store = AppStore()
    @State private var searchText: String = ""
    @State private var searchResults: [DiscoverUser] = []
    @State private var isSearching: Bool = false
    @State private var searchCompleted: Bool = false
    @State private var errorMessage: String? = nil
    @State private var expandedUserId: String? = nil
    @State private var userContent: [String: UserSharedContent] = [:]
    @State private var addedProgramIds: Set<String> = []
    @State private var addedExerciseIds: Set<String> = []
    @State private var showingFollowDuplicate: Bool = false
    @State private var selectedProgram: Program? = nil
    @State private var debounceTask: Task<Void, Never>? = nil
    
    private var followingUsers: [DiscoverUser] {
        let users = store.appData.followingUsers
        let favoriteIds = store.appData.favoriteUserIds
        
        // Sort favorites first
        return users.sorted { user1, user2 in
            let isFav1 = favoriteIds.contains(user1.id)
            let isFav2 = favoriteIds.contains(user2.id)
            if isFav1 != isFav2 {
                return isFav1
            }
            return user1.name < user2.name
        }
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Train together")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.accent.opacity(0.8))
                            .tracking(2)
                        
                        Text("People")
                            .font(Theme.display(32))
                            .foregroundColor(Theme.text)
                            .tracking(1)
                        
                        Text("Find other athletes by name, follow them, and add their programs.")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textDim)
                        
                        TextField("Search athletes", text: $searchText)
                            .font(Theme.body(14))
                            .foregroundColor(Theme.text)
                            .onChange(of: searchText) { newValue in
                                handleSearch(newValue)
                            }
                    }
                    .padding(12)
                    .background(Theme.surface2)
                    .cornerRadius(12)
                    
                    // Search results
                    if isSearching {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                            Text("Searching…")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.textDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else if searchCompleted {
                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.body(14))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else if searchResults.isEmpty && !searchText.isEmpty {
                            Text("No results")
                                .font(Theme.body(14))
                                .foregroundColor(Theme.placeholder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(searchResults) { user in
                                    SearchResultCard(user: user, expandedUserId: $expandedUserId, userContent: $userContent, addedProgramIds: $addedProgramIds, addedExerciseIds: $addedExerciseIds, showingFollowDuplicate: $showingFollowDuplicate, selectedProgram: $selectedProgram, store: store)
                                }
                            }
                        }
                    }
                    
                    // Following section
                    if !followingUsers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Theme.accent)
                                
                                Text("Following (\(followingUsers.count))")
                                    .font(Theme.body(14))
                                    .foregroundColor(Theme.text)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(followingUsers) { user in
                                    FollowingCard(user: user, expandedUserId: $expandedUserId, userContent: $userContent, addedProgramIds: $addedProgramIds, addedExerciseIds: $addedExerciseIds, showingFollowDuplicate: $showingFollowDuplicate, selectedProgram: $selectedProgram, store: store)
                                }
                            }
                        }
                    } else if searchCompleted && searchResults.isEmpty {
                        Text("You're not following anyone yet. Search above to find athletes and follow them.")
                            .font(Theme.body(14))
                            .foregroundColor(Theme.placeholder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingFollowDuplicate) {
            if let program = selectedProgram {
                FollowDuplicateSheet(program: program, showing: $showingFollowDuplicate, store: store)
            }
        }
        .task {
            await store.loadAppData()
        }
    }
    
    private func handleSearch(_ query: String) {
        // Cancel any existing debounce task
        debounceTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            searchCompleted = false
            return
        }
        
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 350ms
            guard !Task.isCancelled else { return }
            
            await performSearch(query)
        }
    }
    
    private func performSearch(_ query: String) async {
        isSearching = true
        searchCompleted = false
        errorMessage = nil
        
        do {
            let results = try await store.searchUsers(query: query)
            await MainActor.run {
                searchResults = results
                isSearching = false
                searchCompleted = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSearching = false
                searchCompleted = true
            }
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let user: DiscoverUser
    @Binding var expandedUserId: String?
    @Binding var userContent: [String: UserSharedContent]
    @Binding var addedProgramIds: Set<String>
    @Binding var addedExerciseIds: Set<String>
    @Binding var showingFollowDuplicate: Bool
    @Binding var selectedProgram: Program?
    @ObservedObject var store: AppStore
    @State private var isLoadingContent: Bool = false
    
    private var isExpanded: Bool {
        expandedUserId == user.id
    }
    
    private var hasSharedContent: Bool {
        user.sharedProgramCount > 0 || user.sharedExerciseCount > 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // User info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    if hasSharedContent {
                        Text("\(user.sharedProgramCount) programs · \(user.sharedExerciseCount) exercises")
                            .font(Theme.body(10))
                            .foregroundColor(Theme.textDim)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        if user.following {
                            try? await store.unfollowUser(userId: user.id)
                        } else {
                            try? await store.followUser(userId: user.id)
                        }
                    }
                }) {
                    Text(user.following ? "Following" : "Follow")
                        .font(Theme.body(12))
                        .foregroundColor(user.following ? Theme.accent : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(user.following ? Theme.surface2 : Theme.accent)
                        .cornerRadius(12)
                }
            }
            
            // Shared content section
            if hasSharedContent {
                Button(action: {
                    toggleExpanded()
                }) {
                    HStack {
                        Text("Shared content")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    if isLoadingContent {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else if let content = userContent[user.id] {
                        SharedContentView(content: content, addedProgramIds: $addedProgramIds, addedExerciseIds: $addedExerciseIds, showingFollowDuplicate: $showingFollowDuplicate, selectedProgram: $selectedProgram, store: store)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private func toggleExpanded() {
        withAnimation {
            if isExpanded {
                expandedUserId = nil
            } else {
                expandedUserId = user.id
                loadContent()
            }
        }
    }
    
    private func loadContent() {
        isLoadingContent = true
        Task {
            do {
                let content = try await store.getUserContent(userId: user.id)
                await MainActor.run {
                    userContent[user.id] = content
                    isLoadingContent = false
                }
            } catch {
                await MainActor.run {
                    isLoadingContent = false
                }
            }
        }
    }
}

// MARK: - Following Card

struct FollowingCard: View {
    let user: DiscoverUser
    @Binding var expandedUserId: String?
    @Binding var userContent: [String: UserSharedContent]
    @Binding var addedProgramIds: Set<String>
    @Binding var addedExerciseIds: Set<String>
    @Binding var showingFollowDuplicate: Bool
    @Binding var selectedProgram: Program?
    @ObservedObject var store: AppStore
    @State private var isLoadingContent: Bool = false
    
    private var isFavorite: Bool {
        store.appData.favoriteUserIds.contains(user.id)
    }
    
    private var canFavorite: Bool {
        !isFavorite && store.appData.favoriteUserIds.count < 5
    }
    
    private var isExpanded: Bool {
        expandedUserId == user.id
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // User info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(Theme.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.text)
                    
                    Text("\(user.sharedProgramCount) programs · \(user.sharedExerciseCount) exercises")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textDim)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            try? await store.unfollowUser(userId: user.id)
                        }
                    }) {
                        Text("Unfollow")
                            .font(Theme.body(12))
                            .foregroundColor(Theme.textDim)
                    }
                    
                    Button(action: {
                        Task {
                            if isFavorite {
                                try? await store.unfavoriteUser(userId: user.id)
                            } else {
                                try? await store.favoriteUser(userId: user.id)
                            }
                        }
                    }) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(isFavorite ? Theme.accent : Theme.textDim)
                    }
                    .disabled(!canFavorite && !isFavorite)
                }
            }
            
            // Shared content section
            Button(action: {
                toggleExpanded()
            }) {
                HStack {
                    Text("Shared content")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                if isLoadingContent {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else if let content = userContent[user.id] {
                    SharedContentView(content: content, addedProgramIds: $addedProgramIds, addedExerciseIds: $addedExerciseIds, showingFollowDuplicate: $showingFollowDuplicate, selectedProgram: $selectedProgram, store: store)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }
    
    private func toggleExpanded() {
        withAnimation {
            if isExpanded {
                expandedUserId = nil
            } else {
                expandedUserId = user.id
                loadContent()
            }
        }
    }
    
    private func loadContent() {
        isLoadingContent = true
        Task {
            do {
                let content = try await store.getUserContent(userId: user.id)
                await MainActor.run {
                    userContent[user.id] = content
                    isLoadingContent = false
                }
            } catch {
                await MainActor.run {
                    isLoadingContent = false
                }
            }
        }
    }
}

// MARK: - Shared Content View

struct SharedContentView: View {
    let content: UserSharedContent
    @Binding var addedProgramIds: Set<String>
    @Binding var addedExerciseIds: Set<String>
    @Binding var showingFollowDuplicate: Bool
    @Binding var selectedProgram: Program?
    @ObservedObject var store: AppStore
    
    var body: some View {
        VStack(spacing: 12) {
            // Programs
            if !content.programs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Programs")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    VStack(spacing: 8) {
                        ForEach(content.programs) { program in
                            programRow(program: program)
                        }
                    }
                }
            }
            
            // Exercises
            if !content.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(Theme.body(12))
                        .foregroundColor(Theme.textDim)
                    
                    VStack(spacing: 8) {
                        ForEach(content.exercises) { exercise in
                            exerciseRow(exercise: exercise)
                        }
                    }
                }
            }
        }
    }
    
    private func programRow(program: Program) -> some View {
        let isAdded = addedProgramIds.contains(program.id)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.text)
                
                Text("\(program.days.count) days")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            if isAdded {
                Button(action: {
                    // Remove program (not implemented yet)
                    addedProgramIds.remove(program.id)
                }) {
                    Text("Remove")
                        .font(Theme.body(10))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: {
                    selectedProgram = program
                    showingFollowDuplicate = true
                }) {
                    Text("Add")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(12)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
    
    private func exerciseRow(exercise: Exercise) -> some View {
        let isAdded = addedExerciseIds.contains(exercise.id)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(Theme.body(12))
                    .foregroundColor(Theme.text)
                
                Text(exercise.primaryMuscle)
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            if isAdded {
                Button(action: {
                    // Remove exercise
                    addedExerciseIds.remove(exercise.id)
                }) {
                    Text("Remove")
                        .font(Theme.body(10))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: {
                    // Add exercise (not implemented yet)
                    addedExerciseIds.insert(exercise.id)
                }) {
                    Text("Add")
                        .font(Theme.body(10))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(12)
        .background(Theme.surface2)
        .cornerRadius(8)
    }
}

// MARK: - Follow vs Duplicate Sheet

struct FollowDuplicateSheet: View {
    let program: Program
    @Binding var showing: Bool
    @ObservedObject var store: AppStore
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(program.name)
                        .font(Theme.display(24))
                        .foregroundColor(Theme.text)
                        .tracking(1)
                    
                    Text("\(program.days.count) days")
                        .font(Theme.body(14))
                        .foregroundColor(Theme.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            try? await store.addSharedProgram(programId: program.id)
                            showing = false
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Follow")
                                    .font(Theme.body(14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.text)
                                
                                Text("Stay linked to creator. Their future edits will sync.")
                                    .font(Theme.body(10))
                                    .foregroundColor(Theme.textDim)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "link")
                                .font(.title3)
                                .foregroundColor(Theme.accent)
                        }
                        .padding(16)
                        .background(Theme.surface)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Duplicate program (not implemented yet)
                        showing = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duplicate")
                                    .font(Theme.body(14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.text)
                                
                                Text("Create a standalone owned copy you can edit.")
                                    .font(Theme.body(10))
                                    .foregroundColor(Theme.textDim)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundColor(Theme.accent)
                        }
                        .padding(16)
                        .background(Theme.surface)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Add Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showing = false
                    }
                }
            }
        }
    }
}