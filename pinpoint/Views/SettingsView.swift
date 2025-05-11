import SwiftUI
import CoreLocation
import CoreMotion

struct SettingsView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var motionManager: MotionHistoryManager
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var locationServicesEnabled = true
    @State private var motionDetectionEnabled = true
    
    var body: some View {
        List {
            Section(header: Text("Permissions")) {
                Toggle("Location Services", isOn: $locationManager.isUpdatingLocation)
                    .onChange(of: locationManager.isUpdatingLocation, initial: false) { newValue, _ in
                        if newValue {
                            locationManager.requestLocationPermission()
                        } else {
                            locationManager.stopLocationUpdates()
                        }
                    }
                Toggle("Motion Detection", isOn: $motionManager.isMonitoring)
                    .onChange(of: motionManager.isMonitoring, initial: false) { newValue, _ in
                        if newValue {
                            motionManager.startMotionUpdates()
                        } else {
                            motionManager.stopMotionUpdates()
                        }
                    }
            }
            
            Section(header: Text("Preferences")) {
                Toggle("Notifications", isOn: $notificationsEnabled)
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                Button("Privacy Policy") {
                    // Action for privacy policy
                }
                Button("Terms of Service") {
                    // Action for terms of service
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            // No need to set toggle state here; it's bound to the manager's state
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(LocationManager())
            .environmentObject(MotionHistoryManager())
    }
} 