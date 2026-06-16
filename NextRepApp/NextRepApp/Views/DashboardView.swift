import SwiftUI

struct DashboardView: View {
    @State private var selectedRoute: AppRoute?
    @State private var selectedProgram: Program?
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.text)
                    Text("Ready to train today?")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Resume workout banner
                Button(action: {
                    print("🏋️ Resume button tapped - activeWorkoutStore.isActive: \(activeWorkoutStore.isActive)")
                    
                    if activeWorkoutStore.isActive {
                        // TODO: Navigate to active workout with current session
                        print("⚠️ Resume workout - need to implement navigation to active workout")
                    } else {
                        print("⚠️ No active workout to resume")
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Resume Workout")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Theme.accent)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                // Stats
                HStack(spacing: 12) {
                    StatCard(title: "Workouts", value: "12")
                    StatCard(title: "This Week", value: "3")
                }
                .padding(.horizontal)
                
                // Recent activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.text)
                    
                    ActivityRow(title: "Chest Day", date: "Today", time: "45 min")
                    ActivityRow(title: "Back Day", date: "Yesterday", time: "38 min")
                    ActivityRow(title: "Leg Day", date: "2 days ago", time: "52 min")
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedRoute) { route in
            switch route {
            case .activeWorkout(let program, let day):
                if let day = day {
                    ActiveWorkoutView(program: program, day: day)
                } else {
                    EmptyView()
                }
            case .programDetail(let program):
                ProgramDetailView(program: program)
            default:
                EmptyView()
            }
        }
        .screenBackground()
    }
}

struct ActivityRow: View {
    let title: String
    let date: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.text)
                Text("\(date) • \(time)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textDim)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Theme.textDim)
        }
        .padding(16)
        .cardStyle()
    }
}