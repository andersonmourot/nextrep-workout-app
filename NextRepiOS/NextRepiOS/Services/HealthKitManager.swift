import HealthKit
import Foundation

@available(iOS 16.0, *)
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned)
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveWorkout(
        exerciseName: String,
        startDate: Date,
        endDate: Date,
        calories: Double,
        completion: @escaping (Bool) -> Void
    ) {
        guard isAuthorized else {
            print("HealthKit not authorized")
            completion(false)
            return
        }
        
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate
        )
        
        let caloriesBurned = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let caloriesSample = HKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            quantity: caloriesBurned,
            start: startDate,
            end: endDate
        )
        
        healthStore.save([workout, caloriesSample]) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save workout: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    }
    
    func saveWorkout(
        program: Program,
        day: ProgramDay,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Bool) -> Void
    ) {
        guard isAuthorized else {
            print("HealthKit not authorized")
            completion(false)
            return
        }
        
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate
        )
        
        // Estimate calories based on workout duration and intensity
        let duration = endDate.timeIntervalSince(startDate)
        let calories = duration * 0.1 // Approximate 6 cal/min for strength training
        let caloriesBurned = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let caloriesSample = HKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            quantity: caloriesBurned,
            start: startDate,
            end: endDate
        )
        
        healthStore.save([workout, caloriesSample]) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save workout: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    }
    
    func getWorkouts(completion: @escaping ([HKWorkout]?) -> Void) {
        guard isAuthorized else {
            print("HealthKit not authorized")
            completion(nil)
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date()),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { samples, error in
            guard let samples = samples as? [HKWorkout], error == nil else {
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            completion(samples)
        }
        
        healthStore.execute(query)
    }
    
    func deleteWorkout(_ workout: HKWorkout, completion: @escaping (Bool) -> Void) {
        healthStore.delete(workout) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to delete workout: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    }
}