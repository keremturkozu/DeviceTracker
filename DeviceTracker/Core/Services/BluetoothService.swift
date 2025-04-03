import Foundation
import CoreBluetooth
import Combine

class BluetoothService: NSObject, ObservableObject {
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var peripherals: [String: CBPeripheral] = [:] // Changed to dictionary for better duplicate handling
    
    // Published properties for UI updates
    @Published var discoveredDevices: [Device] = []
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        
        isScanning = true
        peripherals.removeAll()
        discoveredDevices.removeAll()
        
        // Start scanning for all available services
        // Remove allowDuplicates to prevent multiple updates for the same device
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // Calculate approximate distance based on RSSI with better accuracy for closer devices
    private func calculateDistance(rssi: Int) -> Double {
        // Measured transmission power at 1 meter - replacing with underscore as it's not used in new calculation
        let _ = -65.0
        
        if rssi == 0 {
            return -1.0 // Can't determine distance
        }
        
        // More accurate formula especially for close range
        if rssi >= -50 {
            // Very close, less than 0.5m
            return 0.2
        } else if rssi >= -65 {
            // Close, around 0.5-1m
            return 0.5
        } else if rssi >= -75 {
            // Medium distance 1-2m
            return Double(abs(rssi + 65)) / 10.0
        } else if rssi >= -85 {
            // Far 2-5m
            return 2.0 + Double(abs(rssi + 75)) / 10.0
        } else {
            // Very far, more than 5m
            return 5.0
        }
    }
    
    // Get battery level for a device
    // In a real app, this would be retrieved from the BLE characteristic
    // For demo purposes, we're generating consistent values based on device ID
    private func getBatteryLevel(for peripheralId: String) -> Int {
        // Generate a consistent battery level based on device ID
        // This ensures same device always has same battery level during a session
        let hash = abs(peripheralId.hashValue)
        return (hash % 100) + 1 // 1-100
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            errorMessage = "Bluetooth is powered off"
            stopScanning()
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device"
        case .unauthorized:
            errorMessage = "Bluetooth is not authorized"
        case .resetting:
            errorMessage = "Bluetooth is resetting"
        case .unknown:
            errorMessage = "Bluetooth state is unknown"
        @unknown default:
            errorMessage = "Unknown Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Use peripheral identifier as a unique key
        let peripheralId = peripheral.identifier.uuidString
        
        // Filter out devices with no name
        guard let deviceName = peripheral.name, !deviceName.isEmpty else { return }
        
        // Calculate approximate distance
        let distance = calculateDistance(rssi: RSSI.intValue)
        
        // Get battery level (in a real app, you would get this from the device)
        let batteryLevel = getBatteryLevel(for: peripheralId)
        
        // Store peripheral in our dictionary to prevent duplications
        peripherals[peripheralId] = peripheral
        
        DispatchQueue.main.async {
            // Check if we already discovered this device
            if let existingIndex = self.discoveredDevices.firstIndex(where: { $0.id.uuidString == peripheralId }) {
                // Update existing device
                let existingDevice = self.discoveredDevices[existingIndex]
                existingDevice.distance = distance
                existingDevice.lastSeen = Date()
            } else {
                // Create new device
                let device = Device(
                    id: peripheral.identifier,
                    name: deviceName,
                    distance: distance,
                    batteryLevel: batteryLevel
                )
                
                // Add to our list
                self.discoveredDevices.append(device)
            }
            
            // Sort by distance
            self.discoveredDevices.sort { $0.distance < $1.distance }
        }
    }
} 