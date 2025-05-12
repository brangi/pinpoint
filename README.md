# Pinpoint App Documentation

## Overview
Pinpoint is a SwiftUI-based iOS application designed for location tracking, user profile management, and settings configuration. The app is structured for scalability and maintainability, with clear separation of concerns and extensibility in mind.

---

## Project Structure

```
pinpoint/
├── Assets.xcassets/         # App assets (icons, colors, etc.)
├── Views/                   # All SwiftUI views and managers
│   ├── ContentView.swift    # Main tab-based UI
│   ├── MapView.swift        # Map and location logic
│   ├── ProfileView.swift    # User profile UI
│   ├── SettingsView.swift   # App settings UI
│   ├── LocationManager.swift# Handles CoreLocation logic
│   └── MotionHistoryManager.swift # Handles CoreMotion history
├── pinpointApp.swift        # App entry point
├── Info.plist               # App configuration and permissions
├── default.csv              # Placeholder for required resources
```

---

## Main Components

### 1. App Entry
- **pinpointApp.swift**: Sets up the main SwiftUI scene and logs app state changes (foreground, background, inactive).

### 2. ContentView
- **ContentView.swift**: Implements a tab-based interface with three main tabs: Map, Profile, and Settings.
- On launch, fetches motion history, last known location, and estimates trips.

### 3. Map & Location
- **MapView.swift**: Displays a map, user's current location, and supports pinch-to-zoom and panning. Only recenters on user location the first time or when the user taps the location button.
- **LocationManager.swift**: Handles location permissions, updates, persistent storage of last known location, and logs app state changes.

### 4. Motion History
- **MotionHistoryManager.swift**: Fetches and stores motion activity history using Core Motion, enabling trip estimation after app relaunch.

### 5. Profile & Settings
- **ProfileView.swift**: Displays user profile information.
- **SettingsView.swift**: Manages app preferences and about info.

---

## Data Flow & Persistence
- **LocationManager** stores the last known location in `UserDefaults` for trip estimation after app relaunch.
- **MotionHistoryManager** fetches motion activities since the last trip timestamp.
- **ContentView** coordinates trip estimation logic on app launch.

---

## Permissions & Privacy
- **Info.plist** must include:
  - `NSLocationWhenInUseUsageDescription`: Explains why location is needed.
  - `NSMotionUsageDescription`: Explains why motion data is needed.
- The app requests and logs permission status for both location and motion data.

---

## Logging & Debugging
- App and location state changes are logged to the console for debugging.
- Motion history and trip estimation steps are logged on app launch.
- Extend logging as needed for new features or debugging.

---

## Scalability & Best Practices
- **Separation of Concerns**: Each manager/view handles a single responsibility.
- **Extensibility**: Add new features by creating new managers or views in the `Views/` directory.
- **Persistence**: Use `UserDefaults` for lightweight data; consider CoreData for more complex needs.
- **Testing**: Add unit and UI tests in the `pinpointTests` and `pinpointUITests` directories.
- **.gitignore**: User-specific and build files are ignored for clean version control.

---

## For Developers & AI Agents
- **Follow the existing structure** for new features.
- **Document new components** in this README as the app evolves.
- **Keep logic modular** and avoid monolithic files.
- **Use logging** for all new background or privacy-sensitive features.
- **Update Info.plist** for any new permissions.

---

## Next Steps
- Implement trip interpolation logic using motion and location data.
- Add more detailed logging and analytics as needed.
- Expand settings and profile features as required.

---

## Recent Major Changes (May 2025)

### 1. Dynamic Location Permission UI
- Added a native, non-dismissible modal sheet that blocks the UI if the user has not granted "Always" location permission.
- Added a second modal sheet that appears if Location Services are disabled globally, with instructions to re-enable them.
- The UI updates immediately in response to permission changes using a published state from LocationManager and the locationManagerDidChangeAuthorization delegate.

### 2. Background MQTT Reconnect Logic
- The app disconnects from MQTT when entering the background.
- When a location update is received in the background, the app reconnects to MQTT for 10 seconds, then disconnects again.
- This logic is compliant with iOS background execution policies and is battery-friendly.

### 3. Dynamic distanceFilter for Location Updates
- The app uses Core Motion to detect user activity (walking, running, cycling, driving, stationary).
- The CLLocationManager's distanceFilter is dynamically adjusted based on detected activity for optimal balance between responsiveness and battery life.
- A summary table of recommended distanceFilter values is included in the code for reference.

### 4. Code Quality and Warnings
- Removed all unused variable warnings and improved code clarity.
- All permission and location services checks are now handled via the delegate and published state, following Apple best practices.
- Improved error handling and UI feedback for permission and background state changes.

### 5. User Experience
- The app now guides users through enabling the correct permissions with clear, modern, and adaptive UI.
- The UI is locked until the required permissions are granted, ensuring the app functions as intended.

---

For questions or contributions, update this README to keep documentation current and helpful for all contributors and AI agents. 