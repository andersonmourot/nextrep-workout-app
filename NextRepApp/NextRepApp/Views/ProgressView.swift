import SwiftUI

struct ProgressView: View {
    @State private var selectedRoute: AppRoute?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats cards
                HStack(spacing: 12) {
                    StatCard(title: "Workouts", value: "12")
                    StatCard(title: "This Week", value: "3")
                }
                
                // Navigation options
                VStack(spacing: 12) {
                    NavRow(icon: "fork.knife", title: "Nutrition", route: .nutrition, selectedRoute: $selectedRoute)
                    NavRow(icon: "trophy", title: "Max Tracker", route: .maxTracker, selectedRoute: $selectedRoute)
                    NavRow(icon: "clock", title: "History", route: .history, selectedRoute: $selectedRoute)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Theme.bg)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .navigationDestination(item: $selectedRoute) { route in
            switch route {
            case .nutrition:
                NutritionView()
            case .maxTracker:
                MaxTrackerView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            default:
                EmptyView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cardStyle(12)
    }
}

struct NavRow: View {
    let icon: String
    let title: String
    let route: AppRoute
    @Binding var selectedRoute: AppRoute?
    
    var body: some View {
        Button(action: {
            selectedRoute = route
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accent)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textDim)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}