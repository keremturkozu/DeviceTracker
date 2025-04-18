import SwiftUI

struct SignalView: View {
    let device: Device
    @State private var rssi: Int = -43
    @State private var distance: String = "~21 cm"
    @State private var isGettingCloser: Bool = true
    
    private let barCount = 5
    private let maxRSSI: Int = -30
    private let minRSSI: Int = -90
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        // Device Info Card
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name)
                                    .font(.headline)
                                Text("Connected")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            // Device icon
                            Image(systemName: getDeviceIcon(for: device.name))
                                .font(.system(size: 30))
                                .foregroundColor(Theme.primary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Signal Strength Card
                        VStack(spacing: 12) {
                            Text("Signal Strength")
                                .font(.headline)
                            
                            // Signal bars
                            HStack(spacing: 4) {
                                ForEach(0..<barCount, id: \.self) { index in
                                    Rectangle()
                                        .fill(getSignalBarColor(for: index))
                                        .frame(width: 18, height: 24 + CGFloat(index * 6))
                                        .cornerRadius(4)
                                }
                            }
                            
                            // RSSI and Distance Info
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("RSSI:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(rssi) dBm")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Distance:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(distance)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Direction indicator
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                
                                Text(isGettingCloser ? "Getting Closer" : "Moving Away")
                                    .foregroundColor(isGettingCloser ? .green : .red)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Radar Visualization - Daha büyük
                        VStack {
                            ZStack {
                                // Radar circles
                                ForEach(1...4, id: \.self) { circle in
                                    Circle()
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        .frame(width: CGFloat(circle) * 70)
                                }
                                
                                // Center point (user)
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 18, height: 18)
                                
                                // Device position
                                ZStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(String(device.name.prefix(1)))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .offset(x: 60, y: -70)
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .padding(5)
                        }
                        .padding(.vertical, 5)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // Stop Tracking Button - En alta sabit
                Button(action: {
                    // Stop tracking
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                        Text("Stop Tracking")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Signal Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Periodically update signal values
                startSignalUpdates()
            }
        }
    }
    
    private func getSignalBarColor(for index: Int) -> Color {
        let threshold = normalizedRSSI() * CGFloat(barCount)
        return CGFloat(index) < threshold ? .green : Color.gray.opacity(0.3)
    }
    
    private func normalizedRSSI() -> CGFloat {
        let range = Double(minRSSI - maxRSSI)
        let normalizedValue = Double(rssi - maxRSSI) / range
        return CGFloat(1.0 - min(max(normalizedValue, 0.0), 1.0))
    }
    
    private func startSignalUpdates() {
        // In a real app, we would be getting real RSSI updates
        // For now just simulate changes
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // Randomize RSSI between -35 and -70
            self.rssi = Int.random(in: -70...(-35))
            
            // Calculate estimated distance based on RSSI
            let distanceValue = calculateDistance(rssi: self.rssi)
            self.distance = formatDistance(distance: distanceValue)
            
            // Randomly decide if getting closer
            self.isGettingCloser = Bool.random()
        }
    }
    
    private func calculateDistance(rssi: Int) -> Double {
        // Simple distance calculation based on RSSI
        // In real implementation this would use proper propagation models
        
        // Formula: distance = 10^((TxPower - RSSI)/(10 * n))
        // Where TxPower is the RSSI at 1 meter (often around -59)
        // n is the propagation constant (often around 2)
        
        let txPower = -59
        let n = 2.0
        
        return pow(10.0, Double(txPower - rssi) / (10.0 * n))
    }
    
    private func formatDistance(distance: Double) -> String {
        if distance < 1.0 {
            return "~\(Int(distance * 100)) cm"
        } else {
            return String(format: "~%.1f m", distance)
        }
    }
    
    // Get the appropriate icon based on device name
    private func getDeviceIcon(for deviceName: String) -> String {
        let name = deviceName.lowercased()
        if name.contains("iphone") || name.contains("phone") {
            return "iphone"
        } else if name.contains("macbook") || name.contains("laptop") {
            return "laptopcomputer"
        } else if name.contains("airpods") || name.contains("headphone") || name.contains("earphone") || 
                  name.contains("buds") || name.contains("earpods") || name.contains("jbl") || name.contains("tune") ||
                  name.contains("beats") || name.contains("pod") || name.contains("earbuds") {
            return "airpodspro" // All headphone types use the same icon
        } else if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        } else if name.contains("tv") || name.contains("television") {
            return "tv"
        } else if name.contains("speaker") || name.contains("sound") {
            return "hifispeaker.fill"
        }
        
        return "laptopcomputer" // Default to computer icon
    }
}

#Preview {
    SignalView(device: Device(id: UUID(), name: "MacBook Pro", distance: 0.5, batteryLevel: 80))
} 