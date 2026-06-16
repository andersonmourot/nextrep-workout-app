import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case programs = "Programs"
        case timer = "Timer"
        case search = "Search"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .programs: return "dumbbell.fill"
            case .timer: return "timer"
            case .search: return "magnifyingglass"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.home)
                    .tabItem { EmptyView() }
                
                ProgramsListView()
                    .tag(Tab.programs)
                    .tabItem { EmptyView() }
                
                TimerView()
                    .tag(Tab.timer)
                    .tabItem { EmptyView() }
                
                SearchView()
                    .tag(Tab.search)
                    .tabItem { EmptyView() }
                
                ProfileView()
                    .tag(Tab.profile)
                    .tabItem { EmptyView() }
            }
            
            BottomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(selectedTab == tab ? Theme.accent : Color(hex: "71717A"))
                            .shadow(color: selectedTab == tab ? Theme.accent.opacity(0.5) : .clear, radius: selectedTab == tab ? 8 : 0)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? Theme.accent : Color(hex: "71717A"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Theme.surface)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// Placeholder views for tabs that don't exist yet
struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Dashboard")
                    .font(.title)
                    .padding()
                
                Button("Start Workout") {
                    // TODO: Navigate to active workout
                }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

struct TimerView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Timer")
                    .font(.title)
                    .padding()
                Spacer()
            }
            .navigationTitle("Timer")
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Search People")
                    .font(.title)
                    .padding()
                Spacer()
            }
            .navigationTitle("Search")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Progress")
                    .font(.title)
                    .padding()
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}