import Foundation

enum AppRoute: Hashable {
    // Home tab
    case dashboard
    case activeWorkout(program: Program, day: Day?)
    
    // Programs tab
    case programs
    case programDetail(Program)
    case dayDetail(Program, Day)
    
    // Timer tab
    case timer
    
    // Search tab
    case search
    
    // Profile tab
    case profile
    case progress
    case nutrition
    case maxTracker
    case history
    case settings
    
    // Exercise detail
    case exerciseDetail(Exercise)
}