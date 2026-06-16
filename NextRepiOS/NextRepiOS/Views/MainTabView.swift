import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            // Two top radial glows
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.12),
                    Color.clear
                ]),
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 80 * UIScreen.main.bounds.width / 414,
                endRadius: 40 * UIScreen.main.bounds.width / 414
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.07),
                    Color.clear
                ]),
                center: UnitPoint(x: 1.0, y: 0.0),
                startRadius: 60 * UIScreen.main.bounds.width / 414,
                endRadius: 30 * UIScreen.main.bounds.width / 414
            )
            .ignoresSafeArea()
            
            // Tab content
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                
                ProgramsListView()
                    .tag(1)
                
                TimerView()
                    .tag(2)
                
                PeopleView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            // Custom bottom tab bar overlay
            VStack {
                Spacer()
                BottomTabBar(selectedTab: $selectedTab) { index in
                    selectedTab = index
                }
            }
        }
    }
}

// MARK: - Placeholder Timer View (to be implemented)

struct TimerView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("TIMER")
                    .font(Theme.display(28))
                    .foregroundColor(Theme.text)
                
                Text("Rest timer and workout timer")
                    .font(Theme.body(16))
                    .foregroundColor(Theme.textDim)
            }
            .padding()
        }
    }
}