import SwiftUI
import MapKit
import Contacts

struct DeviceMapView: View {
    let coordinate: CLLocationCoordinate2D
    let deviceName: String
    
    @State private var selectedItem: DeviceAnnotation?
    @State private var position: MapCameraPosition
    @State private var isStandardMapStyle = true // Boolean flag instead of enum comparison
    @State private var userLocation: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss
    
    init(coordinate: CLLocationCoordinate2D, deviceName: String) {
        self.coordinate = coordinate
        self.deviceName = deviceName
        
        // Initialize with a simpler coordinate-based position to avoid deprecation warnings
        _position = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            mainMapView
        }
        .onAppear {
            // Kullanıcı konumunu al
            requestUserLocation()
            
            // Select the device annotation by default to show info card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedItem = DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName)
            }
        }
    }
    
    // Main map view
    private var mainMapView: some View {
        Map(position: $position, selection: $selectedItem) {
            // Device marker
            Annotation(deviceName, coordinate: coordinate) {
                VStack {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Theme.primary)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .annotationTitles(.hidden)
            .tag(DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName))
            
            // User's location
            UserAnnotation()
            
            // Kullanıcı ve cihaz arasındaki mesafeyi çizgi ile göster 
            if let userLocation = userLocation {
                MapPolyline(coordinates: [userLocation, coordinate])
                    .stroke(Color.blue, lineWidth: 3)
                    .mapOverlayLevel(level: .aboveRoads)
            }
        }
        .mapStyle(.standard) // Sadece standart stil kullanılıyor artık
        .mapControls {
            VStack(spacing: 10) {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }
            .padding(.leading, 16)
            .padding(.bottom, 100) // Alt kısımda bilgi kartından kaçınmak için
        }
        .safeAreaInset(edge: .bottom) {
            locationInfoCard
        }
        .navigationTitle("Device Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
    
    // Kullanıcı konumunu isteme
    private func requestUserLocation() {
        // CoreLocation yerine MapKit'in kendi konum izni sistemini kullanıyoruz
        let locationManager = CLLocationManager()
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            if let location = locationManager.location?.coordinate {
                self.userLocation = location
                
                // Hem cihaz hem kullanıcı konumunu gösterecek bir bölge belirle
                if let userLoc = userLocation {
                    let midLat = (userLoc.latitude + coordinate.latitude) / 2
                    let midLon = (userLoc.longitude + coordinate.longitude) / 2
                    
                    // Aralarındaki mesafeyi hesapla
                    let userPoint = MKMapPoint(userLoc)
                    let devicePoint = MKMapPoint(coordinate)
                    let distance = userPoint.distance(to: devicePoint)
                    
                    // Mesafeye göre uygun bir zoom seviyesi belirle (metre cinsinden)
                    let spanDelta = max(0.01, distance / 50000)
                    
                    // Pozisyonu her iki noktayı gösterecek şekilde güncelle
                    DispatchQueue.main.async {
                        self.position = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                                span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
                            )
                        )
                    }
                }
            }
        }
    }
    
    // Location info card at bottom
    @ViewBuilder
    private var locationInfoCard: some View {
        if let selectedItem = selectedItem {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedItem.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Mesafe bilgisini ekle
                        if let userLocation = userLocation {
                            let userPoint = MKMapPoint(userLocation)
                            let devicePoint = MKMapPoint(coordinate)
                            let distance = userPoint.distance(to: devicePoint)
                            
                            if distance < 1000 {
                                Text("Approximately \(Int(distance)) meters away")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Approximately \(String(format: "%.1f", distance/1000)) km away")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Last seen here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    directionsButton
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 5)
            .padding()
        }
    }
    
    // Directions button
    private var directionsButton: some View {
        Button {
            openInMaps()
        } label: {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.primary)
                .cornerRadius(8)
                .shadow(color: Theme.shadowColor, radius: 2, x: 0, y: 1)
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = deviceName
        
        // Open with navigation options
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ] as [String : Any]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
}

// Model for map annotation
struct DeviceAnnotation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DeviceAnnotation, rhs: DeviceAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    DeviceMapView(
        coordinate: CLLocationCoordinate2D(latitude: 37.331820, longitude: -122.031189),
        deviceName: "MacBook Pro"
    )
} 