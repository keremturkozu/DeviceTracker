import SwiftUI

// Tüm metin bileşenlerinin varsayılan olarak SF Pro Rounded kullanması için extension
extension View {
    func defaultAppFont() -> some View {
        self.modifier(DefaultFontModifier())
    }
}

// Varsayılan fontları SF Pro Rounded olarak değiştiren modifier
struct DefaultFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(.body, design: .rounded))
    }
}

// Text bileşenleri için font extension
extension Text {
    func headlineStyle() -> some View {
        self.font(Theme.headlineFont)
            .foregroundColor(Theme.text)
    }
    
    func titleStyle() -> some View {
        self.font(Theme.titleFont)
            .foregroundColor(Theme.text)
    }
    
    func captionStyle() -> some View {
        self.font(Theme.captionFont)
            .foregroundColor(Theme.subtleText)
    }
} 