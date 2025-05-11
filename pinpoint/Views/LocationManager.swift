import Foundation
import CoreLocation
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D? {
        didSet {
            if let loc = location {
                saveLastKnownLocation(loc)
            }
        }
    }
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation: Bool = false
    private var logTimer: Timer?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        setupAppStateLogging()
    }
    
    func requestLocationPermission() {
        print("[LocationManager] requestLocationPermission called. Current status: \(authorizationStatus.rawValue)")
        isUpdatingLocation = true
        manager.requestWhenInUseAuthorization()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("[LocationManager] Permission already granted. Starting updates and logging.")
            manager.startUpdatingLocation()
            startLoggingLocation()
        }
    }
    
    func stopLocationUpdates() {
        print("[LocationManager] stopLocationUpdates called.")
        manager.stopUpdatingLocation()
        stopLoggingLocation()
        isUpdatingLocation = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("[LocationManager] didChangeAuthorization: \(status.rawValue), isUpdatingLocation: \(isUpdatingLocation)")
        authorizationStatus = status
        if (status == .authorizedWhenInUse || status == .authorizedAlways) && isUpdatingLocation {
            print("[LocationManager] Permission granted in delegate. Starting updates and logging.")
            manager.startUpdatingLocation()
            startLoggingLocation()
        } else if status != .authorizedWhenInUse && status != .authorizedAlways {
            print("[LocationManager] Permission denied or revoked. Stopping updates.")
            stopLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationManager] didUpdateLocations called. Locations: \(locations)")
        if let loc = locations.last {
            location = loc.coordinate
        }
    }
    
    private func startLoggingLocation() {
        stopLoggingLocation() // Ensure no duplicate timers
        logTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let loc = self.location,
                  self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways,
                  self.isUpdatingLocation else { return }
            print("[LocationManager] Current location: (lat: \(loc.latitude), lon: \(loc.longitude))")
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
        print("[LocationManager] App did enter background")
    }
    
    @objc private func appWillEnterForeground() {
        print("[LocationManager] App will enter foreground")
    }
    
    @objc private func appDidBecomeActive() {
        print("[LocationManager] App did become active")
    }
    
    @objc private func appWillResignActive() {
        print("[LocationManager] App will resign active")
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
} 