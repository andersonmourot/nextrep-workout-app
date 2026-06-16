import Foundation
import SwiftUI

class AppStore: ObservableObject {
    @Published var appData: AppData = AppData()
    @Published var isAuthenticated: Bool = false
    
    var allExercises: [Exercise] {
        appData.customExercises
    }
    
    init() {
        Task {
            await loadAppData()
        }
    }
    
    func loadAppData() async {
        // Load from UserDefaults or API
        // For now, just use the default
    }
    
    func removeCompletedProgram(id: String) async {
        appData.completedPrograms.removeAll { $0.id == id }
    }
}