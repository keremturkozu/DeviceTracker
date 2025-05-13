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
        
        // Directly focus on the device's location with a closer zoom level
        _position = State(
            initialValue: .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: 300, // Start with a closer view
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
            // Get user location immediately
            requestUserLocation()
            
            // Select device annotation immediately
            selectedItem = DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName)
        }
    }
    
    // Main map view
    private var mainMapView: some View {
        Map(position: $position, selection: $selectedItem) {
            // Device marker
            Annotation(deviceName, coordinate: coordinate) {
                // Device marker with modern appearance
                ZStack {
                    // Outer circle for pulsating effect
                    if isPinpointActive {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(1.3)
                    }
                    
                    // Middle circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Inner icon
                    Image(systemName: getDeviceIcon(for: deviceName))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isPinpointActive ? .red : Theme.primary)
                }
            }
            .annotationTitles(.hidden)
            .tag(DeviceAnnotation(id: "device", coordinate: coordinate, title: deviceName))
            
            // User's location
            UserAnnotation()
            
            // Show distance between user and device with a line
            if let userLocation = userLocation {
                // Stylish line with gradient effect
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
                        
                        // If pinpoint is active, focus exactly on the device
                        if isPinpointActive {
                            // Add a small delay to avoid race condition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.position = .camera(
                                    MapCamera(
                                        centerCoordinate: coordinate,
                                        distance: 200, // Closer view
                                        heading: 0,
                                        pitch: 45 // Reduced angle
                                    )
                                )
                            }
                        } else {
                            // Return to normal view
                            if let userLoc = userLocation {
                                // Add delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showBothLocations(userLocation: userLoc, deviceLocation: coordinate)
                                }
                            } else {
                                // Add delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.position = .camera(
                                        MapCamera(
                                            centerCoordinate: coordinate,
                                            distance: 300.0, // More consistent with initial view
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
    
    // Request user location
    private func requestUserLocation() {
        let locationManager = CLLocationManager()
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            if let location = locationManager.location?.coordinate {
                // Update user location immediately 
                self.userLocation = location
                
                // Adjust the camera only if we're not already in pinpoint mode
                if !isPinpointActive {
                    // Show both locations, but ensure device location is more prominent
                    DispatchQueue.main.async {
                        showBothLocations(userLocation: location, deviceLocation: coordinate)
                    }
                }
            }
        }
    }
    
    // Adjust map to show both locations
    private func showBothLocations(userLocation: CLLocationCoordinate2D, deviceLocation: CLLocationCoordinate2D) {
        // Only show both locations if not in pinpoint mode
        if !isPinpointActive {
            // Calculate midpoint
            let midLat = (userLocation.latitude + deviceLocation.latitude) / 2
            let midLon = (userLocation.longitude + deviceLocation.longitude) / 2
            
            // Calculate distance between points
            let userPoint = MKMapPoint(userLocation)
            let devicePoint = MKMapPoint(deviceLocation)
            let distance = userPoint.distance(to: devicePoint)
            
            // Adjust camera distance based on the gap (with constraints)
            let cameraDistance = min(max(1000, distance * 1.5), 50000)
            
            // Run on main thread
            DispatchQueue.main.async {
                // Update position
                self.position = .camera(
                    MapCamera(
                        centerCoordinate: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                        distance: cameraDistance,
                        heading: 0,
                        pitch: 0
                    )
                )
            }
        }
    }
    
    // Location info card at bottom
    @ViewBuilder
    private var locationInfoCard: some View {
        if let selectedItem = selectedItem {
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 14) {
                    // Device icon
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
                        
                        // Distance information with optimized display
                        if let userLocation = userLocation {
                            let userPoint = MKMapPoint(userLocation)
                            let devicePoint = MKMapPoint(coordinate)
                            let distanceInMeters = userPoint.distance(to: devicePoint)
                            
                            // Use similar format as in the radar view for consistency
                            if distanceInMeters < 5 {
                                Text("Very close")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.green)
                            } else if distanceInMeters < 10 {
                                Text("Within 10 meters")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.green)
                            } else if distanceInMeters < 20 {
                                Text("Nearby")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.orange)
                            } else if distanceInMeters < 100 {
                                Text("Approximately \(Int(distanceInMeters)) meters away")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary)
                            } else if distanceInMeters < 1000 {
                                Text("Several meters away")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.secondary)
                            } else {
                                Text("\(String(format: "%.1f", distanceInMeters/1000)) km away")
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
                
                // If pinpoint is active, focus exactly on the device
                if isPinpointActive {
                    // Add a small delay to avoid race condition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.position = .camera(
                            MapCamera(
                                centerCoordinate: coordinate,
                                distance: 200, // Closer view
                                heading: 0,
                                pitch: 45 // Reduced angle
                            )
                        )
                    }
                } else {
                    // Return to normal view
                    if let userLoc = userLocation {
                        // Add delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showBothLocations(userLocation: userLoc, deviceLocation: coordinate)
                        }
                    } else {
                        // Add delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.position = .camera(
                                MapCamera(
                                    centerCoordinate: coordinate,
                                    distance: 300.0, // More consistent with initial view
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
                 name.contains("earpods") || name.contains("pod") || name.contains("jbl") || name.contains("tune") {
            return "airpodspro"
        } else if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        } else if name.contains("speaker") || name.contains("sound") {
            return "hifispeaker.fill"
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