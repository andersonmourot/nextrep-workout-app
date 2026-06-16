import SwiftUI
import Foundation

struct RootView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var authState = AuthState.shared
    @StateObject private var activeWorkoutStore = ActiveWorkoutStore.shared
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case programs = "Programs"
        case timer = "Timer"
        case search = "Search"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .programs: return "square.grid.2x2"
            case .timer: return "timer"
            case .search: return "magnifyingglass"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        if authState.isAuthenticated {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .dashboard:
                                DashboardView()
                            case .activeWorkout(let program, let day):
                                if let day = day {
                                    ActiveWorkoutView(program: program, day: day)
                                } else {
                                    EmptyView()
                                }
                            case .programDetail(let program):
                                ProgramDetailView(program: program)
                            case .dayDetail(let program, let day):
                                DayView(program: program, day: day)
                            case .exerciseDetail(let exercise):
                                ExerciseDetailView(exercise: exercise)
                            default:
                                EmptyView()
                            }
                        }
                }
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
                
                NavigationStack {
                    ProgramsView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .programs:
                                ProgramsView()
                            case .programDetail(let program):
                                ProgramDetailView(program: program)
                            case .dayDetail(let program, let day):
                                DayView(program: program, day: day)
                            case .activeWorkout(let program, let day):
                                if let day = day {
                                    ActiveWorkoutView(program: program, day: day)
                                } else {
                                    EmptyView()
                                }
                            case .dashboard:
                                DashboardView()
                            case .exerciseDetail(let exercise):
                                ExerciseDetailView(exercise: exercise)
                            default:
                                EmptyView()
                            }
                        }
                }
                .tabItem {
                    Label(Tab.programs.rawValue, systemImage: Tab.programs.icon)
                }
                .tag(Tab.programs)
                
                NavigationStack {
                    TimerView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .timer:
                                TimerView()
                            default:
                                EmptyView()
                            }
                        }
                }
                .tabItem {
                    Label(Tab.timer.rawValue, systemImage: Tab.timer.icon)
                }
                .tag(Tab.timer)
                
                NavigationStack {
                    PeopleView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .search:
                                PeopleView()
                            default:
                                EmptyView()
                            }
                        }
                }
                .tabItem {
                    Label(Tab.search.rawValue, systemImage: Tab.search.icon)
                }
                .tag(Tab.search)
                
                NavigationStack {
                    ProgressView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .profile, .progress:
                                ProgressView()
                            case .nutrition:
                                NutritionView()
                            case .maxTracker:
                                MaxTrackerView()
                            case .history:
                                HistoryView()
                            case .settings:
                                SettingsView()
                            case .programDetail(let program):
                                ProgramDetailView(program: program)
                            case .exerciseDetail(let exercise):
                                ExerciseDetailView(exercise: exercise)
                            default:
                                EmptyView()
                            }
                        }
                }
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
            }
            .preferredColorScheme(.dark)
            .environmentObject(activeWorkoutStore)
            .fullScreenCover(item: $activeWorkoutStore.currentSession) { session in
                ActiveWorkoutView(program: session.program, day: session.day)
                    .environmentObject(activeWorkoutStore)
            }
            .onAppear {
                setupTabBarAppearance()
            }
        } else {
            AuthView()
        }
    }
    
    private func setupTabBarAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.backgroundColor = UIColor(Theme.bg)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }
}

class AuthState: ObservableObject {
    static let shared = AuthState()
    @Published var isAuthenticated: Bool = false
    
    private init() {
        // Check if token exists
        isAuthenticated = KeychainStore.shared.getToken() != nil
    }
    
    func login() {
        isAuthenticated = true
    }
    
    func logout() {
        isAuthenticated = false
        APIClient.shared.logout()
    }
}