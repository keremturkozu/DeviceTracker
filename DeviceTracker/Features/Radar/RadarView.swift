import SwiftUI
import Foundation

struct RadarView: View {
    @StateObject var viewModel = RadarViewModel()
    @State private var selectedDevice: Device?
    @State private var navigateToDetail = false
    @State private var navigateToChat = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 15) {
                    // Header with Title
                    HStack {
                        Text("Device Tracker")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text)
                        
                        Spacer()
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: Theme.shadowColor, radius: 3, x: 0, y: 2)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Radar Display
                    RadarDisplayView(devices: viewModel.devices)
                        .frame(height: 260)
                        .padding(.top, 5)
                    
                    // Nearby Devices List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby Devices")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                        
                        if viewModel.devices.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.subtleText)
                                
                                Text("No devices found")
                                    .foregroundColor(Theme.subtleText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.devices, id: \.id) { device in
                                        DeviceRowView(device: device)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                                    .fill(Color.white)
                                                    .shadow(color: Theme.shadowColor, radius: 4, x: 0, y: 2)
                                            )
                                            .padding(.horizontal)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedDevice = device
                                                navigateToDetail = true
                                            }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Search Button
                    Button {
                        viewModel.toggleScanning()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.isScanning ? "stop.fill" : "magnifyingglass")
                            Text(viewModel.isScanning ? "Stop Scanning" : "Search Devices")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 10)
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert(item: Binding<RadarAlertItem?>(
                get: {
                    guard let errorMessage = viewModel.errorMessage else { return nil }
                    return RadarAlertItem(message: errorMessage)
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alert in
                Alert(
                    title: Text("Error"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
    }
}

// MARK: - Helper Views

struct RadarDisplayView: View {
    let devices: [Device]
    
    @State private var radarAngle: Double = 0
    @State private var pulsateRings = false
    @State private var glowEffect = false
    @State private var showDeviceLabels = true
    @State private var devicePositions: [UUID: (position: CGPoint, opacity: Double)] = [:]
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let centerPoint: CGPoint = CGPoint(x: 130, y: 130)
    private let radarRadius: CGFloat = 130
    
    // Custom radar colors
    private let radarLineColor = Color(hex: "45D455") // Bright green
    private let radarRingColor = Color(hex: "45D455") // Bright green
    
    var body: some View {
        ZStack {
            // Clean light background with clip shape
            Circle()
                .fill(Color.white.opacity(0.98))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    radarLineColor.opacity(0.7),
                                    radarLineColor.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 0)
                .frame(width: radarRadius * 2, height: radarRadius * 2)
            
            // Radar Rings with green appearance
            ForEach([0.33, 0.66, 1.0], id: \.self) { scale in
                Circle()
                    .stroke(
                        radarRingColor.opacity(0.2),
                        lineWidth: 1
                    )
                    .frame(width: radarRadius * 2 * scale, height: radarRadius * 2 * scale)
            }
            
            // Very subtle grid pattern
            ZStack {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(radarRingColor.opacity(0.05))
                        .frame(width: 0.5, height: radarRadius * 2)
                        .rotationEffect(.degrees(Double(i) * 22.5))
                }
            }
            .frame(width: radarRadius * 2, height: radarRadius * 2)
            
            // Single clean radar line with light sweep effect
            ZStack {
                // Base radar line
                Rectangle()
                    .fill(radarLineColor.opacity(0.8))
                    .frame(width: 2, height: radarRadius)
                    
                // Slight glow at the end of the radar line
                Circle()
                    .fill(radarLineColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(y: -radarRadius + 4)
                    .blur(radius: 1)
            }
            .offset(y: -radarRadius/2)
            .position(centerPoint)
            .rotationEffect(.degrees(radarAngle), anchor: .center)
            
            // Clip the radar line to the circle
            .clipShape(Circle().size(CGSize(width: radarRadius * 2, height: radarRadius * 2)))
            
            // My Device in center
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            radarLineColor,
                            radarLineColor.opacity(0.8)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .shadow(color: radarLineColor.opacity(0.5), radius: 3, x: 0, y: 0)
                .position(centerPoint)
            
            // Plot Devices with clean labels
            ForEach(devices, id: \.id) { device in
                let position = devicePositions[device.id]?.position ?? 
                    getInitialDevicePosition(normalizedDistance: getNormalizedDistance(device: device), deviceName: device.name, devices: devices)
                
                ZStack {
                    // Device indicator
                    Circle()
                        .fill(getDeviceColor(distance: device.distance))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    // Device label
                    if showDeviceLabels {
                        VStack(spacing: 0) {
                            // Device name tag
                            Text(device.name)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.7))
                                )
                            
                            // Distance pill
                            Text(device.distance < 1 ? "Very close" : "\(Int(device.distance))m")
                                .font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(getDeviceColor(distance: device.distance))
                                )
                                .offset(y: -3)
                        }
                        .offset(y: -18)
                        .opacity(devicePositions[device.id]?.opacity ?? 1.0)
                    }
                }
                .position(position)
                .animation(.easeInOut(duration: 0.3), value: position)
            }
        }
        .frame(width: 260, height: 260)
        .onAppear {
            // Initialize device positions
            updateDevicePositions()
            
            // Set up animations
            pulsateRings = true
            glowEffect = true
            
            // Set up continuous rotation
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                radarAngle = 360
            }
        }
        .onReceive(timer) { _ in
            // Update device positions less frequently
            if devicePositions.count <= 5 || Int.random(in: 0...2) == 0 {
                updateDevicePositions()
            }
        }
    }
    
    private func updateDevicePositions() {
        for device in devices {
            let normalizedDistance = getNormalizedDistance(device: device)
            
            // If we have an existing position, make a small random movement
            if let existingPosition = devicePositions[device.id]?.position {
                // Reduce movement frequency for better performance
                if Bool.random() {
                    let randomOffsetX = CGFloat.random(in: -0.5...0.5)
                    let randomOffsetY = CGFloat.random(in: -0.5...0.5)
                    
                    let newPosition = CGPoint(
                        x: min(max(existingPosition.x + randomOffsetX, 0), 260),
                        y: min(max(existingPosition.y + randomOffsetY, 0), 260)
                    )
                    
                    // Pulse opacity effect based on the radar sweep
                    let angleInDegrees = atan2(newPosition.y - centerPoint.y, newPosition.x - centerPoint.x) * 180 / .pi
                    let normalizedAngle = (angleInDegrees + 180).truncatingRemainder(dividingBy: 360)
                    let radarSweepAngle = radarAngle.truncatingRemainder(dividingBy: 360)
                    
                    // Increase opacity when radar sweep passes over the device
                    let angularDistance = abs(normalizedAngle - radarSweepAngle)
                    let isNearSweep = angularDistance < 20 || angularDistance > 340
                    
                    let opacity = isNearSweep ? 1.0 : 0.8
                    
                    devicePositions[device.id] = (newPosition, opacity)
                }
            } else {
                // Create initial position
                let initialPosition = getInitialDevicePosition(normalizedDistance: normalizedDistance, deviceName: device.name, devices: devices)
                devicePositions[device.id] = (initialPosition, 0.8)
            }
        }
        
        // Remove devices no longer in the list
        let currentIds = Set(devices.map(\.id))
        devicePositions = devicePositions.filter { currentIds.contains($0.key) }
    }
    
    private func getNormalizedDistance(device: Device) -> Double {
        let distance = min(device.distance, 5)
        return 1 - (distance / 5)
    }
    
    private func getInitialDevicePosition(normalizedDistance: Double, deviceName: String, devices: [Device]) -> CGPoint {
        let radius = radarRadius * (1 - normalizedDistance)
        
        // Use the hash value of the device name to create a consistent but
        // somewhat random angle for the device, making sure different devices
        // don't stack at the same position
        let nameHash = deviceName.hash
        let baseAngle = Double(abs(nameHash % 360))
        
        // Check if this angle would place the device too close to other devices
        var angle = baseAngle
        var attempts = 0
        
        // Try up to 10 different angles if needed to avoid overlapping
        while attempts < 10 {
            let radianAngle = angle * (.pi / 180.0)
            let proposedPosition = CGPoint(
                x: centerPoint.x + radius * Darwin.cos(radianAngle),
                y: centerPoint.y + radius * Darwin.sin(radianAngle)
            )
            
            // Check for overlap with existing positions
            let tooClose = devicePositions.values.contains { existingData in
                let existingPosition = existingData.position
                let distance = sqrt(
                    pow(proposedPosition.x - existingPosition.x, 2) +
                    pow(proposedPosition.y - existingPosition.y, 2)
                )
                return distance < 20 // Minimum distance between devices
            }
            
            if !tooClose || attempts >= 9 {
                // If no overlap, or we've tried too many times, use this angle
                break
            }
            
            // Try a slightly adjusted angle
            angle = (baseAngle + Double((attempts + 1) * 36)).truncatingRemainder(dividingBy: 360)
            attempts += 1
        }
        
        let radianAngle = angle * (.pi / 180.0)
        return CGPoint(
            x: centerPoint.x + radius * Darwin.cos(radianAngle),
            y: centerPoint.y + radius * Darwin.sin(radianAngle)
        )
    }
    
    private func getDeviceColor(distance: Double) -> Color {
        if distance < 1 {
            return Color(hex: "45D455") // Green for close devices
        } else if distance < 2 {
            return Color(hex: "FFA500") // Orange for mid-range
        } else {
            return Color(hex: "FF5C5C") // Red for far devices
        }
    }
}

struct DeviceRowView: View {
    let device: Device
    
    var body: some View {
        HStack(spacing: 15) {
            // Device icon with battery indicator
            ZStack {
                // Battery level indicator as background
                Circle()
                    .fill(Color.white)
                    .frame(width: 46, height: 46)
                
                // Circular battery indicator
                Circle()
                    .trim(from: 0, to: CGFloat(device.batteryLevel) / 100)
                    .fill(device.batteryColor)
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90)) // Start from top
                
                // Device icon
                Image(systemName: getDeviceIcon(for: device.name))
                    .font(.system(size: 22))
                    .foregroundColor(Theme.primary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.background))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.text)
                
                Text(device.formattedDistance)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Theme.subtleText)
            }
            
            Spacer()
            
            // Signal strength indicator
            signalStrengthView(for: device)
                .padding(.trailing, 10)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
    
    private func getDeviceIcon(for deviceName: String) -> String {
        let name = deviceName.lowercased()
        if name.contains("iphone") || name.contains("phone") {
            return "iphone"
        } else if name.contains("macbook") || name.contains("laptop") {
            return "laptopcomputer"
        } else if name.contains("airpods") || name.contains("buds") || name.contains("headphone") || name.contains("earphone") {
            return "airpodspro"
        } else if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        } else if name.contains("tv") || name.contains("television") {
            return "tv"
        }
        return "laptopcomputer"
    }
    
    @ViewBuilder
    private func signalStrengthView(for device: Device) -> some View {
        // Determine if the device is far away
        let isFarAway = device.formattedDistance == "Far away"
        
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(getBarColor(index: index, distance: device.distance, isFarAway: isFarAway))
                    .frame(width: 4, height: 10 + CGFloat(index) * 5)
                    .cornerRadius(2)
            }
        }
    }
    
    private func getBarColor(index: Int, distance: Double, isFarAway: Bool) -> Color {
        if isFarAway {
            // For far away devices, use red for all bars
            return index == 0 ? .red : Theme.primary.opacity(0.2)
        }
        
        let threshold: Double
        switch index {
        case 0: threshold = 3.0
        case 1: threshold = 1.5
        case 2: threshold = 0.5
        default: threshold = 0
        }
        
        return distance <= threshold ? .green : Theme.primary.opacity(0.2)
    }
}

// Alert için yardımcı yapı
struct RadarAlertItem: Identifiable {
    var id = UUID()
    var message: String
}

#Preview {
    RadarView()
} 