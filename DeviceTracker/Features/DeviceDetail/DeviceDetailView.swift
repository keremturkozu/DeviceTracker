import SwiftUI
import MapKit

struct DeviceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DeviceDetailViewModel
    @State private var navigateToSignal = false
    @State private var mapItem: MKMapItem?
    @State private var isShowingMap = false
    @State private var showChatSheet = false
    @State private var alertItem: DeviceAlertItem?
    
    init(device: Device) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device))
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Device Icon with Battery Indicator
                ZStack {
                    // Battery circle background
                    Circle()
                        .fill(.white)
                        .frame(width: 180, height: 180)
                        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
                    
                    // Battery indicator circle - only visible when connected
                    if viewModel.isConnected {
                        // Circular battery indicator background track
                        Circle()
                            .stroke(viewModel.device.batteryColor.opacity(0.2), lineWidth: 4)
                            .frame(width: 178, height: 178)
                        
                        // Circular battery indicator
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.device.batteryLevel) / 100)
                            .stroke(viewModel.device.batteryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 178, height: 178)
                            .rotationEffect(.degrees(-90)) // Start from top
                        
                        // Battery percentage
                        Text("\(viewModel.device.batteryLevel)%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(viewModel.device.batteryColor)
                            .position(x: 90, y: 30)
                    }
                    
                    // Inner white circle for icon background
                    Circle()
                        .fill(Theme.background)
                        .frame(width: 160, height: 160)
                    
                    // Device icon
                    Image(systemName: getDeviceIcon(for: viewModel.device.name))
                        .font(.system(size: 80))
                        .foregroundColor(Theme.primary)
                }
                .padding(.top, 30)
                
                // Connected status
                if viewModel.isConnected {
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.vertical, -15)
                }
                
                // Device Name
                Text(viewModel.device.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.text)
                
                // Action Buttons Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    actionButton(title: "Location", iconName: "location.fill") {
                        viewModel.showLocation()
                    }
                    
                    actionButton(title: "Sound", iconName: "speaker.wave.2.fill") {
                        viewModel.playSound()
                    }
                    
                    actionButton(title: "Last Seen", iconName: "clock.fill") {
                        // Boş action, sadece bilgi göstersin
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            Text(viewModel.lastSeenText)
                                .font(.caption)
                                .foregroundColor(Theme.subtleText)
                                .padding(.bottom, 5)
                        }
                    )
                    
                    actionButton(title: "Signal", iconName: "waveform") {
                        viewModel.startSignal()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connect Button
                Button {
                    viewModel.connect()
                } label: {
                    HStack {
                        Image(systemName: viewModel.isConnected ? "wifi.slash" : "wifi")
                        Text(viewModel.isConnected ? "Disconnect" : "Connect")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.isConnected ? Color.red : Theme.primary)
                    .cornerRadius(Theme.buttonCornerRadius)
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
                    .overlay(
                        Group {
                            if viewModel.isConnecting {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    )
                }
                .disabled(viewModel.isConnecting)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.primary)
                        .imageScale(.large)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isFavorite ? .red : Theme.primary)
                        .imageScale(.large)
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, errorMessage in
            if let message = errorMessage {
                alertItem = DeviceAlertItem(message: message)
                // Clear the error message after showing alert
                viewModel.errorMessage = nil
            }
        }
        .alert(item: $alertItem) { item in
            Alert(
                title: Text("Notification"),
                message: Text(item.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationDestination(isPresented: $viewModel.navigateToSignal) {
            SignalView(device: viewModel.device)
        }
        .navigationDestination(isPresented: $viewModel.navigateToChat) {
            ChatView(device: viewModel.device)
        }
        .sheet(isPresented: $viewModel.navigateToMap) {
            if let location = viewModel.device.location {
                DeviceMapView(coordinate: location, deviceName: viewModel.device.name)
            } else {
                // Konum bulunamadığında kullanıcıya bilgi verelim
                VStack {
                    Text("Location information not available")
                        .font(.headline)
                        .padding()
                    
                    Button("Close") {
                        viewModel.navigateToMap = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
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
            return "airpodspro" // Tüm kulaklık türleri için aynı ikonu kullan
        } else if name.contains("ipad") || name.contains("tablet") {
            return "ipad"
        } else if name.contains("watch") {
            return "applewatch"
        } else if name.contains("tv") || name.contains("television") {
            return "tv"
        } else if name.contains("speaker") || name.contains("sound") {
            return "hifispeaker.fill"
        }
        
        return "laptopcomputer" // Varsayılan olarak bilgisayar ikonu
    }
    
    @ViewBuilder
    private func actionButton(title: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(Theme.primary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: Theme.shadowX, y: Theme.shadowY)
        }
    }
}

// Alert için yardımcı yapı
struct DeviceAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    NavigationStack {
        DeviceDetailView(device: Device(name: "MacBook Pro", distance: 0.8))
    }
} 
