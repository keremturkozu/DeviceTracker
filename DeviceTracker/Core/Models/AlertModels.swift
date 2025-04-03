import Foundation

// Reusable alert model for the app
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
    let title: String
    
    init(message: String, title: String = "Notification") {
        self.message = message
        self.title = title
    }
} 