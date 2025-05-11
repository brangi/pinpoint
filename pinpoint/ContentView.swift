//
//  ContentView.swift
//  pinpoint
//
//  Created by brangi rod on 5/10/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var motionHistoryManager: MotionHistoryManager
    @State private var tripEstimated = false
    @State private var didRequestPermissions = false
    
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            if !didRequestPermissions {
                locationManager.requestLocationPermission()
                motionHistoryManager.startMotionUpdates()
                didRequestPermissions = true
            }
            estimateTripIfNeeded()
        }
    }
    
    private func estimateTripIfNeeded() {
        guard !tripEstimated else { return }
        tripEstimated = true
        // 1. Get last known location (start point)
        let startLocation = locationManager.getLastKnownLocation()
        // 2. Get current location (end point)
        let endLocation = locationManager.location
        // 3. Get motion history since last known location (or last launch)
        let lastTimestamp = UserDefaults.standard.object(forKey: "LastTripTimestamp") as? Date ?? Date().addingTimeInterval(-3600)
        motionHistoryManager.fetchMotionHistory(since: lastTimestamp) { activities in
            print("[ContentView] Motion history activities: \(activities.count)")
            // 4. Interpolate trip (placeholder)
            if let start = startLocation, let end = endLocation {
                print("[ContentView] Estimate trip from (lat: \(start.latitude), lon: \(start.longitude)) to (lat: \(end.latitude), lon: \(end.longitude))")
                // TODO: Interpolate trip using activities
            }
            // Save current timestamp for next launch
            UserDefaults.standard.set(Date(), forKey: "LastTripTimestamp")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(MotionHistoryManager())
}
