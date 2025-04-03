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
                                Image(systemName: "antenna.radiowaves.left.and.right")
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
                        ShareLink(
                            item: URL(string: "https://example.com/devicetracker")!,
                            subject: Text("DeviceTracker App"),
                            message: Text("Check out DeviceTracker app to find your devices!"),
                            preview: SharePreview(
                                "DeviceTracker",
                                image: Image(systemName: "antenna.radiowaves.left.and.right")
                            )
                        ) {
                            HStack {
                                Label("Share DeviceTracker", systemImage: "square.and.arrow.up")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
                        }
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
    
    func contactSupport() {
        // Updated email address
        let email = "turkozukerem@gmail.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
} 