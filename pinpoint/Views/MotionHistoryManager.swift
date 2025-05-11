import Foundation
import CoreMotion

class MotionHistoryManager: ObservableObject {
    private let activityManager = CMMotionActivityManager()
    @Published var activities: [CMMotionActivity] = []
    @Published var isMonitoring = false
    
    func startMotionUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("[MotionHistoryManager] Motion activity not available on this device.")
            return
        }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity = activity else { return }
            self?.activities.append(activity)
            print("[MotionHistoryManager] New motion activity detected: \(activity)")
        }
        isMonitoring = true
    }
    
    func stopMotionUpdates() {
        activityManager.stopActivityUpdates()
        isMonitoring = false
        print("[MotionHistoryManager] Stopped motion updates")
    }
    
    func fetchMotionHistory(since startDate: Date, completion: @escaping ([CMMotionActivity]) -> Void) {
        let now = Date()
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("[MotionHistoryManager] Motion activity not available on this device.")
            completion([])
            return
        }
        activityManager.queryActivityStarting(from: startDate, to: now, to: .main) { activities, error in
            if let error = error {
                print("[MotionHistoryManager] Error fetching motion history: \(error)")
                completion([])
                return
            }
            if let activities = activities {
                self.activities = activities
                print("[MotionHistoryManager] Retrieved \(activities.count) motion activities.")
                completion(activities)
            } else {
                completion([])
            }
        }
    }
} 