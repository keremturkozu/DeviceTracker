import SwiftUI

struct Theme {
    // Colors
    static let background = Color(hex: "e5e5e5")
    static let primary = Color(hex: "00C2FF")
    static let secondary = Color(hex: "00C2FF")
    static let accent = Color(hex: "FF3A6B")
    static let text = Color.black
    static let subtleText = Color.gray
    
    // UI Elements
    static let cornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 10
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    // Shadow
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 5
    static let shadowY: CGFloat = 2
    static let shadowX: CGFloat = 0
    
    // Font
    static let defaultFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let titleFont = Font.system(size: 20, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Theme.primary)
            .foregroundColor(.white)
            .cornerRadius(Theme.buttonCornerRadius)
            .shadow(color: Theme.shadowColor, 
                    radius: Theme.shadowRadius, 
                    x: Theme.shadowX, 
                    y: Theme.shadowY)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        return PrimaryButtonStyle()
    }
} 