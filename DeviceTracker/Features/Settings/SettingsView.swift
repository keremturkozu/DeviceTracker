import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var bluetoothEnabled = true
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    // PERMISSIONS
                    Section("PERMISSIONS") {
                        HStack {
                            Label {
                                Text("Location")
                            } icon: {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Text("Authorized")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Label {
                                Text("Bluetooth")
                            } icon: {
                                Image(systemName: "wifi.circle")
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Text("Authorized")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Label {
                                Text("Notifications")
                            } icon: {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Text("Authorized")
                                .foregroundColor(.green)
                        }
                    }
                    
                    // SHARING
                    Section {
                        Button {
                            shareApp()
                        } label: {
                            HStack {
                                Label("Share DeviceTracker", systemImage: "square.and.arrow.up")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary)
                    } header: {
                        Text("SHARING")
                    }
                    
                    // CONTACT
                    Section {
                        Button {
                            contactSupport()
                        } label: {
                            HStack {
                                Label("Contact Support", systemImage: "envelope")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary)
                    } header: {
                        Text("CONTACT")
                    }
                    
                    // ABOUT
                    Section {
                        NavigationLink {
                            WebViewContainer(urlString: "https://example.com/privacy")
                                .navigationTitle("Privacy Policy")
                        } label: {
                            Text("Privacy Policy")
                                .foregroundColor(Theme.primary)
                        }
                        
                        NavigationLink {
                            WebViewContainer(urlString: "https://example.com/terms")
                                .navigationTitle("Terms of Service")
                        } label: {
                            Text("Terms of Service")
                                .foregroundColor(Theme.primary)
                        }
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("ABOUT")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
        }
    }
    
    func shareApp() {
        // Uygulama paylaşma işlevi
        let url = URL(string: "https://example.com/devicetracker")!
        let activityVC = UIActivityViewController(activityItems: [
            "Check out DeviceTracker app to find your devices!",
            url
        ], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func contactSupport() {
        // E-posta uygulamasını açma işlevi
        let email = "support@devicetracker.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
} 