import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(hex: "0F1117")
        static let backgroundSecondary = Color(hex: "11151C")
        static let cardBackground = Color(hex: "1F2937")
        static let cardBorder = Color(hex: "374151")
        static let textPrimary = Color(hex: "E0E0E5")
        static let textSecondary = Color(hex: "9CA3AF")
        static let textTertiary = Color(hex: "6B7280")
        static let accent = Color(hex: "3B82F6")
        static let accentLight = Color(hex: "60A5FA")
        static let accentHover = Color(hex: "2563EB")
        static let disabled = Color(hex: "4B5563")
        static let disabledText = Color(hex: "9CA3AF")
        static let warning = Color(hex: "F59E0B")
        static let success = Color(hex: "10B981")
        static let error = Color(hex: "EF4444")
    }
    
    enum Dimensions {
        static let cornerRadius: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 26
        static let cardSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 20
        static let cardHeight: CGFloat = 140
        static let iconSize: CGFloat = 48
        static let iconSizeLarge: CGFloat = 64
        static let buttonWidth: CGFloat = 200
        static let buttonHeight: CGFloat = 52
    }
    
    enum Shadows {
        static let card = Color.black.opacity(0.3)
        static let cardHover = Color.black.opacity(0.4)
        static let buttonGlow = Color.blue.opacity(0.3)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

struct CardStyle: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .padding(Theme.Dimensions.cardPadding)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Dimensions.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadius)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Theme.Shadows.card, radius: isHovered ? 12 : 6, x: 0, y: isHovered ? 8 : 4)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: Theme.Dimensions.buttonWidth, height: Theme.Dimensions.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.buttonCornerRadius)
                    .fill(isEnabled ? (configuration.isPressed ? Theme.Colors.accentHover : Theme.Colors.accent) : Theme.Colors.disabled)
            )
            .shadow(
                color: isEnabled && !configuration.isPressed ? Theme.Shadows.buttonGlow : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
