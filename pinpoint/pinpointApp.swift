//
//  pinpointApp.swift
//  pinpoint
//
//  Created by brangi rod on 5/10/25.
//

import SwiftUI
import CocoaMQTT

@main
struct pinpointApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionHistoryManager = MotionHistoryManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(motionHistoryManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // print("[App] App is active (foreground)")
                MQTTManager.shared.connect()
            case .inactive:
                // print("[App] App is inactive (paused)")
                break
            case .background:
                // print("[App] App is in background")
                MQTTManager.shared.disconnect()
            @unknown default:
                // print("[App] App is in an unknown state")
                break
            }
        }
    }
}
