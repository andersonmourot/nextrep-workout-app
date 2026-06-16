import Foundation
import WatchConnectivity
import WatchKit

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var currentWorkout: ActiveWorkoutData?
    @Published var currentExercise: String = ""
    @Published var currentSet = 1
    @Published var remainingTime = 0
    @Published var isRunning = false
    
    private let session = WCSession.default
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.handleApplicationContext(applicationContext)
        }
    }
    
    // MARK: - Message Handling
    
    private func handleMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "toggleTimer":
            toggleTimer()
        case "toggleSet":
            if let set = message["set"] as? Int {
                toggleSet(set)
            }
        case "syncWorkout":
            if let workoutData = message["workout"] as? [String: Any] {
                syncWorkout(workoutData)
            }
        default:
            break
        }
    }
    
    private func handleApplicationContext(_ context: [String: Any]) {
        if let exercise = context["currentExercise"] as? String {
            currentExercise = exercise
        }
        if let set = context["currentSet"] as? Int {
            currentSet = set
        }
        if let time = context["remainingTime"] as? Int {
            remainingTime = time
        }
        if let running = context["isRunning"] as? Bool {
            isRunning = running
        }
    }
    
    // MARK: - Phone → Watch Communication
    
    func sendWorkoutData(_ workout: ActiveWorkoutData) {
        let message: [String: Any] = [
            "action": "syncWorkout",
            "workout": [
                "exercise": workout.exerciseName ?? "",
                "set": workout.currentSet,
                "totalSets": workout.totalSets
            ]
        ]
        
        if session.activationState == .activated {
            try? session.updateApplicationContext(message)
        }
    }
    
    func sendTimerUpdate(time: Int, isRunning: Bool, phase: String) {
        let context: [String: Any] = [
            "remainingTime": time,
            "isRunning": isRunning,
            "phase": phase
        ]
        
        if session.activationState == .activated {
            try? session.updateApplicationContext(context)
        }
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        // Notify phone app to toggle timer
        NotificationCenter.default.post(name: .toggleTimerFromWatch, object: nil)
    }
    
    private func toggleSet(_ set: Int) {
        // Notify phone app to toggle set
        NotificationCenter.default.post(name: .toggleSetFromWatch, object: nil, userInfo: ["set": set])
    }
    
    private func syncWorkout(_ data: [String: Any]) {
        if let exercise = data["exercise"] as? String,
           let set = data["set"] as? Int,
           let totalSets = data["totalSets"] as? Int {
            currentExercise = exercise
            currentSet = set
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let toggleTimerFromWatch = Notification.Name("toggleTimerFromWatch")
    static let toggleSetFromWatch = Notification.Name("toggleSetFromWatch")
    static let workoutUpdatedFromPhone = Notification.Name("workoutUpdatedFromPhone")
}