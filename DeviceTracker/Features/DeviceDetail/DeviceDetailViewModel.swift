import Foundation
import Combine
import CoreLocation
import MultipeerConnectivity

class DeviceDetailViewModel: NSObject, ObservableObject {
    // MARK: - Properties
    let device: Device
    
    @Published var isFavorite: Bool
    @Published var lastSeenText: String = ""
    @Published var errorMessage: String?
    @Published var navigateToChat: Bool = false
    @Published var navigateToMap: Bool = false
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    
    // Location Manager to get user's location
    private let locationManager = CLLocationManager()
    
    // Multipeer Connectivity
    private var session: MCSession?
    private var advertiser: MCAdvertiserAssistant?
    private var browser: MCNearbyServiceBrowser?
    private let peerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceType = "device-tracker"
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        self.device = Device(name: "Unknown Device")
        self.isFavorite = false
        super.init()
    }
    
    init(device: Device) {
        self.device = device
        self.isFavorite = device.isFavorite
        super.init()
        
        updateLastSeenText()
        setupMultipeerConnectivity()
        setupLocationManager()
        
        // Update last seen text periodically
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateLastSeenText()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    func toggleFavorite() {
        device.isFavorite.toggle()
        isFavorite = device.isFavorite
    }
    
    func connect() {
        if isConnected {
            disconnect()
            return
        }
        
        isConnecting = true
        
        // Start browsing for devices
        browser?.startBrowsingForPeers()
        
        // Simulate connection success after a brief delay
        // In a real app, this would wait for actual connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.isConnecting = false
            self.isConnected = true
            
            // Update battery level when connected (simulate retrieval)
            if self.device.batteryLevel == 0 {
                self.device.batteryLevel = Int.random(in: 20...100)
            }
        }
    }
    
    func disconnect() {
        isConnected = false
        browser?.stopBrowsingForPeers()
        session?.disconnect()
    }
    
    func playSound() {
        if isConnected {
            // In a real app, this would send a message to the peer
            // to play a sound on the device
            sendMessageToPeers(message: "PLAY_SOUND")
            self.errorMessage = "Sound played on device"
        } else {
            self.errorMessage = "Please connect to the device first"
        }
    }
    
    func showLocation() {
        if isConnected {
            // Kullanıcının mevcut konumunu kullanarak cihazın olası konumunu tahmin edelim
            requestLocation()
        } else {
            self.errorMessage = "Please connect to the device first"
        }
    }
    
    func startChat() {
        if isConnected {
            navigateToChat = true
        } else {
            self.errorMessage = "Please connect to the device first"
        }
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Uygulamayı başlatır başlatmaz konum izni isteyelim
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func requestLocation() {
        // Konum hizmetlerinin durumunu kontrol et
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // İzin isteyelim ve kullanıcı izin verince haritayı açalım
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Konum almayı deneyelim
            locationManager.requestLocation()
            
            // Konum alamasak bile haritayı hemen açalım
            // Kullanıcı deneyimini iyileştirmek için
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Henüz konum yoksa İstanbul'da bir yeri gösterelim
                if self.device.location == nil {
                    let istanbulLat = 41.0082
                    let istanbulLng = 28.9784
                    self.device.location = CLLocationCoordinate2D(
                        latitude: istanbulLat,
                        longitude: istanbulLng
                    )
                }
                
                // Haritaya git
                self.navigateToMap = true
            }
        case .denied, .restricted:
            self.errorMessage = "Konum hizmetleri devre dışı. Lütfen cihaz ayarlarından etkinleştirin."
        @unknown default:
            self.errorMessage = "Bilinmeyen konum izni durumu"
        }
    }
    
    private func updateLastSeenText() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        lastSeenText = formatter.localizedString(for: device.lastSeen, relativeTo: Date())
    }
    
    private func setupMultipeerConnectivity() {
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        browser?.delegate = self
        
        advertiser = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session!)
        advertiser?.delegate = self
        advertiser?.start()
    }
    
    private func sendMessageToPeers(message: String) {
        guard let session = session, !session.connectedPeers.isEmpty else {
            return
        }
        
        // Convert message to data
        guard let data = message.data(using: .utf8) else { return }
        
        // Send to all connected peers
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // Bluetooth sinyal gücü kullanarak mesafeyi tahmin et ve konum oluştur 
    private func estimateDeviceLocation(fromUserLocation userLocation: CLLocationCoordinate2D, openMap: Bool = false) {
        // Bluetooth sinyali ile hesaplanmış mesafeyi simüle edelim
        // Gerçek uygulamada bu RSSI değerine göre hesaplanır
        let estimatedDistanceInMeters = Double(device.distance * 100) // Örnek: 0.8 -> 80m
        
        // Rastgele bir yön seç (gerçek uygulamada triangülasyon kullanılır)
        let randomBearing = Double.random(in: 0..<360)
        
        // Mesafe ve yön kullanarak cihazın tahmini konumunu hesapla
        let deviceLocation = calculateCoordinate(from: userLocation, 
                                               distance: estimatedDistanceInMeters,
                                               bearing: randomBearing)
        
        // Cihazın konumunu güncelle
        device.location = deviceLocation
        
        // Haritaya git - sadece açıkça istenirse (Location butonuna basılınca)
        if openMap {
            DispatchQueue.main.async {
                self.navigateToMap = true
            }
        }
    }
    
    // Mesafe ve yön kullanarak yeni bir koordinat hesapla
    private func calculateCoordinate(from coordinate: CLLocationCoordinate2D, 
                                    distance: Double, 
                                    bearing: Double) -> CLLocationCoordinate2D {
        let distanceRadians = distance / 6371000.0 // Dünya yarıçapı (metre)
        let bearingRadians = bearing * Double.pi / 180.0
        let lat1 = coordinate.latitude * Double.pi / 180.0
        let lon1 = coordinate.longitude * Double.pi / 180.0
        
        let lat2 = asin(sin(lat1) * cos(distanceRadians) + cos(lat1) * sin(distanceRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(lat1), cos(distanceRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180.0 / Double.pi, 
                                    longitude: lon2 * 180.0 / Double.pi)
    }
}

// MARK: - CLLocationManagerDelegate
extension DeviceDetailViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.first?.coordinate {
            // Kullanıcının konumunu kullanarak cihazın olası konumunu tahmin et
            estimateDeviceLocation(fromUserLocation: userLocation, openMap: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = "Failed to get your location: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Sadece Location butonuna basıldığında konum isteneceği için
            // burada otomatik olarak konum istemiyoruz
            break
        case .denied, .restricted:
            self.errorMessage = "Konum hizmetleri devre dışı. Lütfen cihaz ayarlarından etkinleştirin."
        case .notDetermined:
            // Henüz karar verilmemiş, kullanıcı izin isteğini bekliyor
            break
        @unknown default:
            break
        }
    }
}

// MARK: - MCSessionDelegate
extension DeviceDetailViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                self?.isConnected = true
                self?.isConnecting = false
            case .connecting:
                self?.isConnecting = true
            case .notConnected:
                self?.isConnected = false
                self?.isConnecting = false
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data from peers
        if let message = String(data: data, encoding: .utf8) {
            print("Received message: \(message)")
            
            // Handle specific messages
            if message.starts(with: "BATTERY_LEVEL:") {
                let components = message.components(separatedBy: ":")
                if components.count > 1, let batteryLevel = Int(components[1]) {
                    DispatchQueue.main.async { [weak self] in
                        self?.device.batteryLevel = batteryLevel
                    }
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not implemented for this app
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not implemented for this app
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not implemented for this app
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension DeviceDetailViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Found a peer, try to connect
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Lost connection to a peer
        if session?.connectedPeers.isEmpty == true {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Failed to start browsing: \(error.localizedDescription)"
            self?.isConnecting = false
        }
    }
}

// MARK: - MCAdvertiserAssistantDelegate
extension DeviceDetailViewModel: MCAdvertiserAssistantDelegate {
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        // Invitation dismissed
    }
    
    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        // Will present invitation
    }
} 