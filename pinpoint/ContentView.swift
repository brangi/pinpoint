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
    @State private var showLocationSheet = false // For 'Always' permission
    @State private var showLocationServicesSheet = false // For global Location Services
    
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
        // Show Location Services sheet with higher priority
        .sheet(isPresented: $showLocationServicesSheet, content: {
            LocationServicesSheet(openSettings: openSettings)
                .interactiveDismissDisabled(true)
        })
        // Show 'Always' permission sheet if needed
        .sheet(isPresented: $showLocationSheet, content: {
            LocationPermissionSheet(openSettings: openSettings)
                .interactiveDismissDisabled(true)
        })
        .onAppear {
            if !didRequestPermissions {
                locationManager.requestLocationPermission()
                motionHistoryManager.startMotionUpdates()
                didRequestPermissions = true
            }
            estimateTripIfNeeded()
        }
        .onReceive(locationManager.$locationAccessState) { state in
            showLocationServicesSheet = (state == .servicesDisabled)
            showLocationSheet = (state == .notAlways)
        }
    }
    
    // Open app settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
            // print("[ContentView] Motion history activities: \(activities.count)")
            // 4. Interpolate trip (placeholder)
            if startLocation != nil && endLocation != nil {
                // print("[ContentView] Estimate trip from (lat: \(start.latitude), lon: \(start.longitude)) to (lat: \(end.latitude), lon: \(end.longitude))")
                // TODO: Interpolate trip using activities
            }
            // Save current timestamp for next launch
            UserDefaults.standard.set(Date(), forKey: "LastTripTimestamp")
        }
    }
}

// MARK: - Location Permission Sheet
struct LocationPermissionSheet: View {
    var openSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.accentColor)
                .padding(.top, 32)
            Text("Set Location to 'Always'")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("To work correctly, this app needs to always access your location.\n\n1. In Settings, select Location\n2. Tap on Always")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: openSettings) {
                Label("Go to Settings", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Location Services Disabled Sheet
struct LocationServicesSheet: View {
    var openSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.red)
                .padding(.top, 32)
            Text("Enable Location Services")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Location Services are turned off for all apps.\n\n1. In Settings, select Privacy & Security > Location Services\n2. Turn on Location Services and allow access for this app.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: openSettings) {
                Label("Go to Settings", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(MotionHistoryManager())
}
