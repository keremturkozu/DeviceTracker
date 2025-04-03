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
                    
                    // Radar Display - slightly reduced height
                    EnhancedRadarView(devices: viewModel.devices)
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
                    
                    // Search Button - thicker and blue color
                    Button {
                        viewModel.toggleScanning()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.isScanning ? "stop.circle" : "play.circle")
                            Text(viewModel.isScanning ? "Stop Scanning" : "Search Devices")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12) // Increased padding
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.isScanning ? Color.red : Theme.primary) // Changed to Theme.primary
                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                    }
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

// MARK: - Enhanced Radar View

struct EnhancedRadarView: View {
    let devices: [Device]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var radarAngle: Double = 0
    @State private var pulsateAnimation = false
    @State private var devicePositions: [UUID: (position: CGPoint, opacity: Double)] = [:]
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    // Radar geometry properties
    @State private var viewSize: CGSize = .zero
    private var radarRadius: CGFloat {
        min(viewSize.width, viewSize.height) / 2 - 10 // 10px padding from edges
    }
    private var centerPoint: CGPoint {
        CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
    }
    
    // Custom radar colors
    private let radarLineColor = Color(hex: "45D455")
    private let radarRingColor = Color(hex: "45D455").opacity(0.7)
    private let radarInnerRingColor = Color(hex: "45D455").opacity(0.3)
    private let radarBackgroundColor = Color.white.opacity(0.98)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Radar background
                Circle()
                    .stroke(radarRingColor, lineWidth: 2)
                    .background(Circle().fill(radarBackgroundColor))
                    .overlay(
                        Circle()
                            .stroke(radarInnerRingColor, lineWidth: 1)
                            .scaleEffect(0.75)
                    )
                    .overlay(
                        Circle()
                            .stroke(radarInnerRingColor, lineWidth: 1)
                            .scaleEffect(0.5)
                    )
                    .overlay(
                        Circle()
                            .stroke(radarInnerRingColor, lineWidth: 1)
                            .scaleEffect(0.25)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Radar line with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [radarLineColor, radarLineColor.opacity(0)]),
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: radarRadius, height: 3)
                    .offset(x: radarRadius/2)
                    .rotationEffect(Angle(degrees: radarAngle))
                
                // Center dot
                Circle()
                    .fill(radarLineColor)
                    .frame(width: 8, height: 8)
                
                // Clip view to ensure devices don't appear outside radar
                ZStack {
                    // Device dots on radar
                    ForEach(devices, id: \.id) { device in
                        let distanceNormalized = getNormalizedDistance(device: device)
                        let position = devicePositions[device.id]?.position ?? 
                            getInitialDevicePosition(normalizedDistance: distanceNormalized, deviceName: device.name, devices: devices)
                        
                        ZStack {
                            // Outer ring (signal indicator)
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 20, height: 20)
                            
                            // Inner dot (device)
                            Circle()
                                .fill(getDeviceColor(distance: device.distance))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                        .opacity(0.7)
                                )
                        }
                        .shadow(color: getDeviceColor(distance: device.distance).opacity(0.6), radius: 3, x: 0, y: 0)
                        .position(position)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: position)
                        
                        // Device labels - ensure they stay inside radar boundary
                        VStack(spacing: 2) {
                            Text(device.name.count > 15 ? String(device.name.prefix(12)) + "..." : device.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            // Distance indicator
                            Text(device.distance < 1 ? "Very close" : "\(Int(device.distance))m")
                                .font(.system(size: 8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(getDeviceColor(distance: device.distance)).opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(3)
                        }
                        // Position labels with consideration for radar edges and label visibility
                        .position(getOptimalLabelPosition(devicePosition: position, radarCenter: centerPoint, radarRadius: radarRadius))
                        .opacity(devicePositions[device.id]?.opacity ?? 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: position)
                    }
                }
                .clipShape(Circle())
                
                // Scanning pulse effect
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(radarLineColor.opacity(0.5), lineWidth: 4)
                    .rotationEffect(Angle(degrees: radarAngle))
                
                // Pulse effect
                Circle()
                    .stroke(radarLineColor.opacity(0.15), lineWidth: 2)
                    .scaleEffect(pulsateAnimation ? 1.0 : 0.97)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulsateAnimation
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                self.viewSize = geometry.size
                
                // Initialize device positions
                updateDevicePositions()
                
                // Start animations
                pulsateAnimation = true
                
                // Set up continuous rotation
                withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                    radarAngle = 360
                }
            }
            .onChange(of: geometry.size) { newSize in
                self.viewSize = newSize
                // Recalculate positions when view size changes
                updateDevicePositions()
            }
            .onReceive(timer) { _ in
                // Rotate radar line continuously
                withAnimation {
                    radarAngle = (radarAngle + 2).truncatingRemainder(dividingBy: 360)
                }
                
                // Update device positions less frequently
                if Int.random(in: 0...10) == 0 {
                    updateDevicePositions()
                }
            }
        }
    }
    
    // Get optimal position for device label to ensure visibility and prevent clipping
    private func getOptimalLabelPosition(devicePosition: CGPoint, radarCenter: CGPoint, radarRadius: CGFloat) -> CGPoint {
        // Calculate vector from center to device
        let dx = devicePosition.x - radarCenter.x
        let dy = devicePosition.y - radarCenter.y
        
        // Calculate distance from center to device
        let distance = sqrt(dx*dx + dy*dy)
        
        // Calculate unit vector
        let unitDx = dx / max(distance, 0.01) // Avoid division by zero
        let unitDy = dy / max(distance, 0.01)
        
        // Calculate angle in degrees
        let angle = atan2(dy, dx) * 180 / .pi
        
        // Decide label position based on angle
        // For devices on the right half of the radar, place label to the left of the device
        // For devices on the left half, place label to the right of the device
        let isRightHalf = abs(angle) < 90
        
        let labelOffsetY = 18.0 // Vertical offset
        
        var labelX = devicePosition.x
        let labelY = devicePosition.y + labelOffsetY
        
        // Add horizontal offset to labels on right side to prevent clipping
        if isRightHalf && devicePosition.x > radarCenter.x + radarRadius * 0.5 {
            labelX = min(devicePosition.x, radarCenter.x + radarRadius - 60) // Ensure labels don't go off the right edge
        }
        
        // Ensure the label Y position doesn't exceed the radar boundary
        let maxY = radarCenter.y + radarRadius - 30 // 30px from edge
        
        return CGPoint(x: labelX, y: min(labelY, maxY))
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
                        x: min(max(existingPosition.x + randomOffsetX, centerPoint.x - radarRadius),
                              centerPoint.x + radarRadius),
                        y: min(max(existingPosition.y + randomOffsetY, centerPoint.y - radarRadius),
                              centerPoint.y + radarRadius)
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
        // Adjust to keep items more inside the radar
        let distance = min(device.distance, 5)
        // Scale factor to keep items away from edge
        let scaleFactor = 0.8
        return (1 - (distance / 5)) * scaleFactor
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
            return Color.green // Green for close devices
        } else if distance < 2 {
            return Color.orange // Orange for mid-range
        } else {
            return Color.red // Red for far devices
        }
    }
}

// MARK: - Device Row View

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