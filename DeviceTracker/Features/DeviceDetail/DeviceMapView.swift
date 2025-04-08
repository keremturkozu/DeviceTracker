import SwiftUI
import MapKit
import Contacts

struct DeviceMapView: View {
    let coordinate: CLLocationCoordinate2D
    let deviceName: String
    
    @State private var selectedItem: DeviceAnnotation?
    @State private var position: MapCameraPosition
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var isPinpointActive = false
    @Environment(\.dismiss) private var dismiss
    
    init(coordinate: CLLocationCoordinate2D, deviceName: String) {
        self.coordinate = coordinate
        self.deviceName = deviceName
        
        // Direkt cihazın konumuna odaklanacak şekilde ayarla
        _position = State(
            initialValue: .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: 500, // Yakın bir mesafeden başla
                    heading: 0,
                    pitch: 0
                )
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            mainMapView
        }
        .onAppear {
            // Kullanıcı konumunu hemen al
            requestUserLocation()
            
            // Cihaz annotasyonunu hemen seç
            selectedItem = DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName)
        }
    }
    
    // Main map view
    private var mainMapView: some View {
        Map(position: $position, selection: $selectedItem) {
            // Device marker
            Annotation(deviceName, coordinate: coordinate) {
                // Cihaz işaretçisi - daha modern görünüm
                ZStack {
                    // Dış halka - pulsating effect için
                    if isPinpointActive {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(1.3)
                    }
                    
                    // Orta halka
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // İç icon
                    Image(systemName: getDeviceIcon(for: deviceName))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isPinpointActive ? .red : Theme.primary)
                }
            }
            .annotationTitles(.hidden)
            .tag(DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName))
            
            // User's location
            UserAnnotation()
            
            // Kullanıcı ve cihaz arasındaki mesafeyi çizgi ile göster - daha modern
            if let userLocation = userLocation {
                // Daha şık çizgi ve gradient efekti
                MapPolyline(coordinates: [userLocation, coordinate])
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, isPinpointActive ? .red : Theme.primary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: isPinpointActive ? [8, 4] : [])
                    )
                    .mapOverlayLevel(level: .aboveRoads)
            }
        }
        .mapStyle(isPinpointActive ? .hybrid : .standard)
        .mapControls {
            VStack(spacing: 10) {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }
            .padding(.leading, 16)
            .padding(.bottom, 120)
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isPinpointActive.toggle()
                        
                        // Pinpoint aktifse tam olarak cihazın üzerine odaklan
                        if isPinpointActive {
                            // Delay ekleyerek olası race condition'ı önle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.position = .camera(
                                    MapCamera(
                                        centerCoordinate: coordinate,
                                        distance: 200, // Daha yakın
                                        heading: 0,
                                        pitch: 45 // Açıyı azalttım
                                    )
                                )
                            }
                        } else {
                            // Normal görünüme dön
                            if let userLoc = userLocation {
                                // Delay ekle
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showBothLocations(userLocation: userLoc, deviceLocation: coordinate)
                                }
                            } else {
                                // Delay ekle
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.position = .camera(
                                        MapCamera(
                                            centerCoordinate: coordinate,
                                            distance: 500,
                                            heading: 0,
                                            pitch: 0
                                        )
                                    )
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: isPinpointActive ? "location.fill" : "location")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isPinpointActive ? .red : Theme.primary)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
    
    // Kullanıcı konumunu isteme
    private func requestUserLocation() {
        let locationManager = CLLocationManager()
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            if let location = locationManager.location?.coordinate {
                self.userLocation = location
                
                // Hem kullanıcı hem de cihazı gösterecek şekilde ayarla
                showBothLocations(userLocation: location, deviceLocation: coordinate)
            }
        }
    }
    
    // Her iki konumu da gösterecek şekilde haritayı ayarla
    private func showBothLocations(userLocation: CLLocationCoordinate2D, deviceLocation: CLLocationCoordinate2D) {
        // Pinpoint modunda değilse iki konumu birden göster
        if !isPinpointActive {
            // İki nokta arasındaki orta nokta
            let midLat = (userLocation.latitude + deviceLocation.latitude) / 2
            let midLon = (userLocation.longitude + deviceLocation.longitude) / 2
            
            // Aralarındaki mesafeyi hesapla
            let userPoint = MKMapPoint(userLocation)
            let devicePoint = MKMapPoint(deviceLocation)
            let distance = userPoint.distance(to: devicePoint)
            
            // Mesafeye göre kamera mesafesini ayarla (sınırlamalarla)
            let cameraDistance = min(max(1000, distance * 1.5), 50000)
            
            // Ana thread'de çalıştır
            DispatchQueue.main.async {
                // Position güncellemesini try-catch bloğu içine al
                do {
                    self.position = .camera(
                        MapCamera(
                            centerCoordinate: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                            distance: cameraDistance,
                            heading: 0,
                            pitch: 0
                        )
                    )
                } catch {
                    print("Camera positioning error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Location info card at bottom
    @ViewBuilder
    private var locationInfoCard: some View {
        if let selectedItem = selectedItem {
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 14) {
                    // Laptop icon
                    Image(systemName: getDeviceIcon(for: deviceName))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Theme.primary)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedItem.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        
                        // Mesafe bilgisini ekle
                        if let userLocation = userLocation {
                            let userPoint = MKMapPoint(userLocation)
                            let devicePoint = MKMapPoint(coordinate)
                            let distance = userPoint.distance(to: devicePoint)
                            
                            if distance < 1000 {
                                Text("Approximately \(Int(distance)) meters away")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary)
                            } else {
                                Text("Approximately \(String(format: "%.1f", distance/1000)) km away")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary)
                            }
                        } else {
                            Text("Last seen here")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    pinpointButton
                    directionsButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    // Pinpoint button
    private var pinpointButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                isPinpointActive.toggle()
                
                // Pinpoint aktifse tam olarak cihazın üzerine odaklan
                if isPinpointActive {
                    // Delay ekleyerek olası race condition'ı önle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.position = .camera(
                            MapCamera(
                                centerCoordinate: coordinate,
                                distance: 200, // Daha yakın
                                heading: 0,
                                pitch: 45 // Açıyı azalttım
                            )
                        )
                    }
                } else {
                    // Normal görünüme dön
                    if let userLoc = userLocation {
                        // Delay ekle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showBothLocations(userLocation: userLoc, deviceLocation: coordinate)
                        }
                    } else {
                        // Delay ekle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.position = .camera(
                                MapCamera(
                                    centerCoordinate: coordinate,
                                    distance: 500,
                                    heading: 0,
                                    pitch: 0
                                )
                            )
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: isPinpointActive ? "scope.fill" : "scope")
                    .font(.system(size: 16, weight: .semibold))
                Text("Pinpoint")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(isPinpointActive ? Color.red : Theme.primary)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // Directions button
    private var directionsButton: some View {
        Button {
            openInMaps()
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.turn.up.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Directions")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(Theme.primary)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
    
    // Cihaz tipine göre uygun ikon getir
    private func getDeviceIcon(for deviceName: String) -> String {
        let name = deviceName.lowercased()
        if name.contains("iphone") || name.contains("phone") {
            return "iphone"
        } else if name.contains("macbook") || name.contains("laptop") {
            return "laptopcomputer"
        } else if name.contains("airpods") || name.contains("headphone") || 
                 name.contains("earpods") || name.contains("pod") {
            return "airpodspro"
        } else if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        }
        
        return "laptopcomputer" // Default
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