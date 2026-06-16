import WidgetKit
import SwiftUI

struct NextRepWidget: Widget {
    let kind: String = "NextRepWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextRepProvider()) { entry in
            entry
        }
        .configurationDisplayName("NextRep Workout")
        .description("Track your workouts and rest timers")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

struct NextRepProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextRepEntry {
        NextRepEntry(date: Date(), exerciseName: "Ready to Workout", remainingTime: 0, phase: .ready)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NextRepEntry) -> ()) {
        let entry = NextRepEntry(date: Date(), exerciseName: "Ready to Workout", remainingTime: 0, phase: .ready)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = NextRepEntry(date: Date(), exerciseName: "Ready to Workout", remainingTime: 0, phase: .ready)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct NextRepEntry: TimelineEntry {
    let date: Date
    let exerciseName: String
    let remainingTime: Int
    let phase: TimerPhase
    
    enum TimerPhase: String {
        case ready
        case work
        case rest
        case completed
    }
}

struct NextRepWidgetView: View {
    let entry: NextRepEntry
    
    var body: some View {
        switch entry.phase {
        case .ready:
            readyView
        case .work:
            workView
        case .rest:
            restView
        case .completed:
            completedView
        }
    }
    
    var readyView: some View {
        VStack {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundColor(.green)
            Text("Ready to Workout")
                .font(.headline)
        }
        .containerBackground(.fill.tertiary)
    }
    
    var workView: some View {
        VStack {
            Text(entry.exerciseName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(entry.remainingTime)s")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("WORK")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .containerBackground(.green.opacity(0.1))
    }
    
    var restView: some View {
        VStack {
            Text("Rest")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("\(entry.remainingTime)s")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Next: \(entry.exerciseName)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .containerBackground(.orange.opacity(0.1))
    }
    
    var completedView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            Text("Workout Complete")
                .font(.headline)
        }
        .containerBackground(.green.opacity(0.1))
    }
}

@main
struct NextRepWidgetBundle: WidgetBundle {
    var body: some WidgetConfiguration {
        NextRepWidget()
    }
}