import Foundation
import CoreLocation
import SwiftData
import SwiftUI

@Model
class Device {
    var id: UUID
    var name: String
    var distance: Double // in meters
    var lastSeen: Date
    var isFavorite: Bool
    var latitude: Double?
    var longitude: Double?
    var chatHistory: [ChatMessage]
    var batteryLevel: Int // Added battery level (0-100)
    
    init(id: UUID = UUID(), name: String, distance: Double = 0, lastSeen: Date = Date(), isFavorite: Bool = false, batteryLevel: Int = 0) {
        self.id = id
        self.name = name
        self.distance = distance
        self.lastSeen = lastSeen
        self.isFavorite = isFavorite
        self.batteryLevel = batteryLevel
        self.chatHistory = []
    }
    
    // Helper computed property for formatting distance with more intuitive descriptions
    var formattedDistance: String {
        if distance < 0.3 {
            return "Very close"
        } else if distance < 1.0 {
            return "Within 1m"
        } else if distance < 3.0 {
            return String(format: "%.1fm away", distance)
        } else if distance < 5.0 {
            return "Few meters away"
        } else {
            return "Far away"
        }
    }
    
    // Use computed property for location since CLLocationCoordinate2D can't be stored directly
    var location: CLLocationCoordinate2D? {
        get {
            guard let latitude = latitude, let longitude = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }
    
    // Get color for battery level
    var batteryColor: Color {
        if batteryLevel > 70 {
            return .green
        } else if batteryLevel > 30 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ChatMessage: Codable, Hashable {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isFromUser: Bool) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFromUser = isFromUser
    }
} 