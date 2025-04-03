import Foundation
import Combine
import SwiftUI

class RadarViewModel: ObservableObject {
    // MARK: - Dependencies
    private let bluetoothService: BluetoothService
    private let locationService: LocationService
    
    // MARK: - Publishers
    @Published var devices: [Device] = []
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(bluetoothService: BluetoothService = BluetoothService(),
         locationService: LocationService = LocationService()) {
        self.bluetoothService = bluetoothService
        self.locationService = locationService
        
        setupBindings()
        requestPermissions()
    }
    
    // MARK: - Public Methods
    func startScanning() {
        bluetoothService.startScanning()
    }
    
    func stopScanning() {
        bluetoothService.stopScanning()
    }
    
    func toggleScanning() {
        isScanning ? stopScanning() : startScanning()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Subscribe to Bluetooth service updates
        bluetoothService.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.devices = devices
            }
            .store(in: &cancellables)
        
        bluetoothService.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)
        
        bluetoothService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
        
        // Handle Location service errors
        locationService.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$errorMessage)
    }
    
    private func requestPermissions() {
        locationService.requestAuthorization()
    }
} 