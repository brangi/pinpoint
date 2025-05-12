import Foundation
import CoreLocation
import Combine
import UIKit
import CoreMotion

// Enum to represent location access state for UI
enum LocationAccessState {
    case servicesDisabled
    case notAlways
    case always
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D? {
        didSet {
            if let location = location {
                saveLastKnownLocation(location)
            }
        }
    }
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation: Bool = false
    @Published var locationAccessState: LocationAccessState = .notAlways // For UI
    private var logTimer: Timer?
    private var mqttDisconnectTimer: Timer?
    
    // Summary Table for distanceFilter values:
    // | Activity         | Recommended distanceFilter |
    // |-----------------|---------------------------|
    // | Walking         | 10 meters                 |
    // | Running         | 10 meters                 |
    // | Cycling         | 15 meters                 |
    // | Driving         | 20 meters                 |
    // | Stationary      | 50+ meters                |
    // | Unknown/Default | 10 meters                 |
    
    private let activityManager = CMMotionActivityManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // default value
        startMonitoringActivity() // Start dynamic filtering
        setupAppStateLogging()
    }
    
    func requestLocationPermission() {
        // print("[LocationManager] requestLocationPermission called. Current status: \(authorizationStatus.rawValue)")
        isUpdatingLocation = true
        manager.requestWhenInUseAuthorization()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // print("[LocationManager] Permission already granted. Starting updates and logging.")
            manager.startUpdatingLocation()
            startLoggingLocation()
        }
    }
    
    func stopLocationUpdates() {
        // print("[LocationManager] stopLocationUpdates called.")
        manager.stopUpdatingLocation()
        stopLoggingLocation()
        isUpdatingLocation = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // print("[LocationManager] didChangeAuthorization: \(status.rawValue), isUpdatingLocation: \(isUpdatingLocation)")
        authorizationStatus = status
        if (status == .authorizedWhenInUse || status == .authorizedAlways) && isUpdatingLocation {
            // print("[LocationManager] Permission granted in delegate. Starting updates and logging.")
            manager.startUpdatingLocation()
            startLoggingLocation()
        } else if status != .authorizedWhenInUse && status != .authorizedAlways {
            // print("[LocationManager] Permission denied or revoked. Stopping updates.")
            stopLocationUpdates()
        }
        updateLocationAccessState()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // print("[LocationManager] didUpdateLocations called. Locations: \(locations)")
        if let _ = locations.last {
            location = locations.last?.coordinate
        }
        let appState = UIApplication.shared.applicationState
        if appState == .background {
            // print("[LocationManager] App is in BACKGROUND. Triggering MQTT reconnect for 10 seconds due to location update.")
            if !MQTTManager.shared.isConnected /* && !isConnecting, but isConnecting is private */ {
                MQTTManager.shared.connect()
            } else {
                // print("[LocationManager] MQTT already connected or connecting, not reconnecting.")
            }
            mqttDisconnectTimer?.invalidate()
            mqttDisconnectTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                // print("[LocationManager] Disconnecting MQTT after 10 seconds (background location-triggered test)")
                MQTTManager.shared.disconnect()
            }
        } else {
            // print("[LocationManager] App is in FOREGROUND. MQTT remains connected as normal.")
            mqttDisconnectTimer?.invalidate()
            mqttDisconnectTimer = nil
        }
    }
    
    private func startLoggingLocation() {
        stopLoggingLocation() // Ensure no duplicate timers
        logTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let loc = self.location,
                  self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways,
                  self.isUpdatingLocation else { return }
            // print("[LocationManager] Current location: (lat: \(loc.latitude), lon: \(loc.longitude))")
        }
    }
    
    private func stopLoggingLocation() {
        logTimer?.invalidate()
        logTimer = nil
    }
    
    private func setupAppStateLogging() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        // print("[LocationManager] App did enter background")
    }
    
    @objc private func appWillEnterForeground() {
        // print("[LocationManager] App will enter foreground")
    }
    
    @objc private func appDidBecomeActive() {
        // print("[LocationManager] App did become active")
    }
    
    @objc private func appWillResignActive() {
        // print("[LocationManager] App will resign active")
    }
    
    // MARK: - Persistent Storage for Last Known Location
    private let lastLocationKey = "LastKnownLocation"
    
    private func saveLastKnownLocation(_ coordinate: CLLocationCoordinate2D) {
        let dict = ["lat": coordinate.latitude, "lon": coordinate.longitude]
        UserDefaults.standard.set(dict, forKey: lastLocationKey)
    }
    
    func getLastKnownLocation() -> CLLocationCoordinate2D? {
        if let dict = UserDefaults.standard.dictionary(forKey: lastLocationKey) as? [String: Double],
           let lat = dict["lat"], let lon = dict["lon"] {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Start monitoring user activity and adjust distanceFilter dynamically
    private func startMonitoringActivity() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateDistanceFilter(for: activity)
        }
    }
    
    // Adjust distanceFilter based on detected activity
    private func updateDistanceFilter(for activity: CMMotionActivity) {
        if activity.walking {
            manager.distanceFilter = 10 // meters
            // print("[LocationManager] Activity: Walking, distanceFilter set to 10m")
        } else if activity.running {
            manager.distanceFilter = 10 // meters
            // print("[LocationManager] Activity: Running, distanceFilter set to 10m")
        } else if activity.cycling {
            manager.distanceFilter = 15 // meters
            // print("[LocationManager] Activity: Cycling, distanceFilter set to 15m")
        } else if activity.automotive {
            manager.distanceFilter = 20 // meters
            // print("[LocationManager] Activity: Driving, distanceFilter set to 20m")
        } else if activity.stationary {
            manager.distanceFilter = 50 // meters
            // print("[LocationManager] Activity: Stationary, distanceFilter set to 50m")
        } else {
            manager.distanceFilter = 10 // meters (default)
            // print("[LocationManager] Activity: Unknown, distanceFilter set to 10m")
        }
    }
    
    private func updateLocationAccessState() {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways:
            locationAccessState = .always
        case .denied, .restricted:
            locationAccessState = .servicesDisabled
        default:
            locationAccessState = .notAlways
        }
    }
} 