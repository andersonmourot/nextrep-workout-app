import SwiftUI

struct ProgramDetailView: View {
    let program: Program
    @State private var isActive = false
    @StateObject private var store = AppStore()
    @State private var selectedRoute: AppRoute?
    @State private var selectedDay: Day?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero card
                VStack(alignment: .leading, spacing: 16) {
                    // Category pill
                    if let category = program.category {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accent.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Title
                    Text(program.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.text)
                    
                    // Meta info
                    HStack(spacing: 16) {
                        if let coach = program.coach {
                            Label(coach, systemImage: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textDim)
                        }
                        if let level = program.level {
                            Label(level, systemImage: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                    
                    // Description
                    if let description = program.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textDim)
                            .lineLimit(3)
                    }
                    
                    // Set as Active button
                    if isActive {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.caption)
                            Text("Active Program")
                        }
                        .buttonStyle(GhostButton())
                        .disabled(true)
                    } else {
                        Button(action: {
                            Task {
                                // TODO: await store.setActiveProgram(program.id)
                                isActive = true
                            }
                        }) {
                            Text("Set as Active Program")
                        }
                        .buttonStyle(PrimaryButton())
                    }
                }
                .padding(16)
                .cardStyle()
                
                // Days section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Workout Days")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.text)
                    
                    VStack(spacing: 12) {
                        ForEach(program.days) { day in
                            Button(action: {
                                selectedDay = day
                            }) {
                                DayCard(day: day)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
            .background(Theme.bg)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Program Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRoute) { route in
            switch route {
            case .activeWorkout(let program, let day):
                if let day = day {
                    ActiveWorkoutView(program: program, day: day)
                } else {
                    EmptyView()
                }
            case .dayDetail(let program, let day):
                DayView(program: program, day: day)
            default:
                EmptyView()
            }
        }
        .navigationDestination(item: $selectedDay) { day in
            DayView(program: program, day: day)
        }
        .screenBackground()
    }
}

struct DayCard: View {
    let day: Day
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.name ?? "Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                if let focus = day.focus {
                    Text(focus)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textDim)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Theme.textDim)
        }
        .padding(16)
        .cardStyle()
    }
}