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
        // Share functionality - fixed to work with SwiftUI
        let appURL = URL(string: "https://example.com/devicetracker")!
        let message = "Check out DeviceTracker app to find your devices!"
        
        let activityVC = UIActivityViewController(
            activityItems: [message, appURL],
            applicationActivities: nil
        )
        
        // Get the current window scene and present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // On iPad, we need to specify a source for the popover
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
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