import ActivityKit
import SwiftUI
import WidgetKit
import UserNotifications

@available(iOS 16.2, *)
struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: Int
        var phase: TimerPhase
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        
        enum TimerPhase: String, Codable {
            case work
            case rest
            case completed
        }
    }
}

@available(iOS 16.2, *)
class RestTimerManager: ObservableObject {
    @Published var activity: Activity<RestTimerAttributes>?
    
    func startLiveActivity(
        exerciseName: String,
        currentSet: Int,
        totalSets: Int,
        initialTime: Int,
        phase: RestTimerAttributes.ContentState.TimerPhase
    ) {
        let attributes = RestTimerAttributes()
        let initialState = RestTimerAttributes.ContentState(
            remainingTime: initialTime,
            phase: phase,
            exerciseName: exerciseName,
            currentSet: currentSet,
            totalSets: totalSets
        )
        
        do {
            activity = try Activity<RestTimerAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }
    
    func updateLiveActivity(
        remainingTime: Int,
        phase: RestTimerAttributes.ContentState.TimerPhase
    ) {
        guard let activity = activity else { return }
        
        let updatedState = RestTimerAttributes.ContentState(
            remainingTime: remainingTime,
            phase: phase,
            exerciseName: activity.content.state.exerciseName,
            currentSet: activity.content.state.currentSet,
            totalSets: activity.content.state.totalSets
        )
        
        Task {
            await activity.update(using: .init(state: updatedState, staleDate: nil))
        }
    }
    
    func stopLiveActivity() {
        Task {
            await activity?.end(using: .init(state: activity.content.state, staleDate: nil))
            activity = nil
        }
    }
}

@available(iOS 16.2, *)
struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.exerciseName)
                    .font(.headline)
                
                HStack {
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(context.state.remainingTime))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(context.state.phase == .work ? .green : .orange)
                }
                
                HStack {
                    Text(context.state.phase.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(context.state.phase == .work ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                        .foregroundColor(context.state.phase == .work ? .green : .orange)
                        .cornerRadius(8)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                Region(
                    leading: .trailing,
                    content: {
                        Text(formatTime(context.state.remainingTime))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(context.state.phase == .work ? .green : .orange)
                    }
                )
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}