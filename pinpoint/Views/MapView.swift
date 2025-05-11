import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var hasCenteredOnUser = false
    
    var body: some View {
        Map(position: $position, interactionModes: [.zoom, .pan]) {
            if let coordinate = locationManager.location {
                Annotation("You are here", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
        }
        .onReceive(locationManager.$location) { coordinate in
            if let coordinate = coordinate, !hasCenteredOnUser {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                hasCenteredOnUser = true
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationTitle("Map")
        .navigationBarItems(trailing: Button(action: {
            if let coordinate = locationManager.location {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }) {
            Image(systemName: "location.fill")
        })
    }
}

#Preview {
    NavigationView {
        MapView()
            .environmentObject(LocationManager())
    }
} 